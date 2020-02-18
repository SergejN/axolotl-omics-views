#!/usr/bin/env perl

#   File:
#       mailer.pm
#
#   Description:
#       Contains the axolotl website mailer module, which is used to send e-mails.
#
#   Version:
#       1.0.1
#
#   Date:
#       25.04.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use Axolotl::HTML;
use Axolotl::ATAPI::Constants;
use Net::SMTP;
use MIME::Base64;
use Axolotl::ATAPI::SettingsManager;
use Axolotl::webpage;

package Mailer;
{
    sub new
    {
        my ($class, $strSettingsFile) = @_;
        my $sm = new SettingsManager($strSettingsFile);
        my $self = {server => $sm->getSetting('MAILING', 'server'),
                    port => $sm->getSetting('MAILING', 'port'),
                    user => $sm->getSetting('MAILING', 'user'),
                    pass => $sm->getSetting('MAILING', 'pass')};
        bless $self, $class;
        return $self;
    }
    
    sub sendMail
    {
        my ($self, $strRecipient, $strSubject, $strContent) = @_;
        my @arrTime = localtime(time);
        my $strCurrentYear = $arrTime[5]+1900;
        my $doc = new HTMLdocument();
        $doc->addExternalResource('stylesheet', 'text/css', 'https://www.axolotl-omics.org/css/mail.css');
        my $wrapper = $doc->createElement('div', {id => 'content-wrapper'});
        my $content = $doc->createElement('div', {id => 'email-content'});
        # Header.
        my $header = $doc->createElement('div', {id => 'email-header'});
        my $a = $doc->createElement('a', {id => 'header-logo', attributes => {href => 'https://www.axolotl-omics.org'}});
        my $img = $doc->createElement('img', {attributes => {width => '400',
                                                             height => '66',
                                                             src => 'https://www.axolotl-omics.org/images/header/logo.png'}});
        $a->appendChild($img);
        $header->appendChild($a);
        $content->appendChild($header);
        # Body.
        my $body = $doc->createElement('div', {id => 'email-body'});
        $body->setInnerHTML($strContent);
        $content->appendChild($body);
        # Footer.
        my $footer = $doc->createElement('div', {id => 'email-footer'});
        my $logo = $doc->createElement('div', {id => 'footer-logo'});
        $a = $doc->createElement('a', {attributes => {href => 'https://www.axolotl-omics.org'}});
        $img = $doc->createElement('img', {attributes => {width => '186',
                                                          height => '50',
                                                          src => 'https://www.axolotl-omics.org/images/footer/logo-bottom.png'}});
        $a->appendChild($img);
        $logo ->appendChild($a);
        my $copyright = $doc->createElement('span', {id => 'copyright'});
        $copyright->setInnerHTML("&copy; 2012-$strCurrentYear Sergej Nowoshilow<br />".
                                 '<a href="http://www.axolotl-omics.org">&nbsp;&nbsp;&nbsp;&nbsp;Axolotl-omics.org team</a>');
        $logo->appendChild($copyright);
        $footer->appendChild($logo);
        $content->appendChild($footer);
        $wrapper->appendChild($content);
        my $root = $doc->getRootElement();
        $root->appendChild($wrapper);
        # Send e-mail.
        my $smtp = Net::SMTP->new(Host => $self->{server},
                                  Port => $self->{port},
                                  Debug => 0);

        return 0 unless($smtp);
        
        $smtp->starttls();
        $smtp->datasend("AUTH LOGIN\n");  
        $smtp->response();
        $smtp->datasend(::encode_base64($self->{user}));
        $smtp->response();
        $smtp->datasend(::encode_base64($self->{pass}));
        $smtp->response();

        $smtp->mail($self->{user});               
        $smtp->to($strRecipient);                       
        $smtp->data();
        $smtp->datasend("Content-type: text/html\n");
        $smtp->datasend("To: $strRecipient\n");
        $smtp->datasend("From: no-reply\@axolotl-omics.org\n");
        $smtp->datasend("Subject: $strSubject\n");
        $smtp->datasend("\n");
        $smtp->datasend($doc->generateHTML());
        $smtp->dataend();                         
        $smtp->quit;
        return 1;
    }
}

1;
