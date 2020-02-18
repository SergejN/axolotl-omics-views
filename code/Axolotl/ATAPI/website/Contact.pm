#!/usr/bin/env perl

#   File:
#       Contact.pm
#
#   Description:
#       Contains the Contact core module of the Axolotl Transcriptome API (ATAPI).
#
#   Version:
#       1.0.7
#
#   Date:
#       12.03.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;
use warnings;

use Axolotl::ATAPI::Constants;
use Axolotl::Mailer;
use File::Temp qw/ tempfile tempdir /;


package Contact;
{
    my $MODULE = 'Contact';

    sub new
    {
        my $class = shift;
        my $self = {_db => undef, _fnAddNodes => undef};
        bless $self, $class;
        return $self;
    }
    
    # Common plug-in methods.
    sub init
    {
        my ($self, $hDB, $fnAddNodes, $ps) = @_;
        $self->{_db} = $hDB;
        $self->{_fnAddNodes} = $fnAddNodes;
        $self->{_mailing} = $ps->getSetting('CONTACT', 'mailing');
        $self->{_email} = $ps->getSetting('CONTACT', 'sendto');
        return $MODULE;
    }
    
    sub getDescription
    {
       return "Encapsulates methods for sending messages, both contact and feedback, using the website";
    }
    
    sub skipDocumentation
    {
        return 1;
    }
    
    sub execute
    {
        my ($self, %hmParams) = @_;
        my $strMethod = $hmParams{_method};
        my $refMethodParams = $hmParams{_parameters};
        my $xmldoc = $hmParams{_xmldoc};
        my $xmldata = $hmParams{_xmldata};
        my $xmlerr = $hmParams{_xmlerr};
        # Execute the method.
        if($strMethod eq 'sendMessage')
        {
            return $self->sendMessage($refMethodParams, $xmldoc, $xmldata, $xmlerr);
        }
        else
        {
            $xmlerr->addChild($xmldoc->createTextNode("The method '$MODULE.$strMethod' was not found"));
            return Constants::ERR_METHOD_NOT_FOUND;
        }
    }
    
    sub sendMessage
    {
        my ($self, $refParams, $xmldoc, $xmldata, $xmlerr) = @_;
        my %hmTypes = ('contact' =>  {_value => Constants::MT_CONTACT, _msg => 'message', _notify => 'message'},
                       'feedback' => {_value => Constants::MT_FEEDBACK, _msg => 'feedback', _notify => 'feedback message'},
                       'bug' =>      {_value => Constants::MT_BUGREPORT, _msg => 'bug report', _notify => 'bug report'});
        my $strType = lc($refParams->{type});
        my $iType = $hmTypes{$strType}->{_value};
        if(!$iType)
        {
            $xmlerr->addChild($xmldoc->createTextNode("Invalid message type"));
            return Constants::ERR_INVALID_PARAMETER;
        }
        my $strName = $refParams->{name};
        $strName =~ s/'/\\'/g;
        $strName = 'anonymous' unless $strName;
        my $strEmail = $refParams->{email};
        $strEmail =~ s/'/\\'/g;
        $strEmail = '' unless $strEmail;
        my $strMsg = $refParams->{message};
        if(!$strMsg)
        {
            $xmlerr->addChild($xmldoc->createTextNode("No message specified"));
            return Constants::ERR_NOT_ENOUGH_PARAMETERS;
        }
        $strMsg =~ s/'/\\'/g;
        my $strQuery = "INSERT INTO Message (type, name, email, message) VALUES (?, ?, ?, ?);";
        my $statement = $self->{_db}->prepare($strQuery);
        $statement->execute($iType, $strName, $strEmail, $strMsg);
        my $response = $xmldoc->createElement('response');
        $response->addChild($xmldoc->createTextNode("Thank you for your $hmTypes{$strType}->{_msg}."));
        $xmldata->addChild($response);
        
        # Send notification to the administrator.
        my $child_pid = fork();
        if($child_pid == 0) 
        {
            my $strContent = "Dear administrator,<br /><br />".
                             "a new $hmTypes{$strType}->{_notify} has been posted by $strName ($strEmail):".
                             "<div id=\"email-msg\">$strMsg</div>".
                             "<br /><br /><br />Sincerely,<br />Axolotl-omics.org server";
            my $mailer = new Mailer($self->{_mailing});
            $mailer->sendMail($self->{_email}, 'New message has been posted', $strContent);

            $strContent = "Dear $strName,<br /><br />".
                          "thank you for your message. It has been forwarded to the webmaster.".
                          "<br /><br /><br />Sincerely,<br />Axolotl-omics.org server";
            $mailer->sendMail($strEmail, 'Thank you!', $strContent);
            exit(0);
        }

        return Constants::ERR_OK;
    }
}

1;
