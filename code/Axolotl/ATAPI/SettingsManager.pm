#!/usr/bin/env perl

#   File:
#       SettingsManager.pm
#
#   Description:
#       Contains the SettingsManager module.
#
#   Version:
#       1.5.0
#
#   Date:
#       01.02.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use Crypt::CBC;
use MIME::Base64;
use Sys::Hostname;


package SettingsManager;
{
    sub new
    {
        my ($class, $strFilename) = @_;
        my $self = {_settings => parseSettingsFile($strFilename)};
        bless $self, $class;
        return $self;
    }

    sub parseSettingsFile
    {
        my ($strFile) = @_;
        my $refSettings = {};
        return $refSettings if !(-e $strFile);
        open(IN, $strFile);
        my $strBlockName = undef;
        while(<IN>)
        {
            chomp();
            next if(substr($_,0,1) eq '#');
            next if !$_;
            # New block.
            if($_ =~ m/\[([A-Za-z0-9]+)\]/)
            {
                    $strBlockName = $1;
                    if(!$refSettings->{$strBlockName})
                    {
                        $refSettings->{$strBlockName} = {};
                    }
                    next;
            }
            # Setting.
            my @arrPair = split(/=/, $_, 2);
            $refSettings->{$strBlockName}->{$arrPair[0]} = $arrPair[1];
        }
        close(IN);
        return $refSettings;
    }
    
    sub getSetting
    {
        my ($self, $strBlock, $strSetting, $bEncrypted) = @_;
        my $strValue = $self->{_settings}->{$strBlock}->{$strSetting};
        #$strValue = decrypt($strBlock, $strSetting, $strValue) if($bEncrypted);
        return $strValue;
    }
    
    sub decrypt
    {
        my ($strBlock, $strSetting, $strValue) = @_;
        $strValue = MIME::Base64::decode_base64($strValue);
        my $cipher = Crypt::CBC->new(-key      => "$strBlock_$strSetting",
                                     -cipher   => 'Blowfish');
        return $cipher->decrypt($strValue);
    }
    
    sub encrypt
    {
        my ($strBlock, $strSetting, $strValue) = @_;
        my $cipher = Crypt::CBC->new(-key      => "$strBlock_$strSetting",
                                     -cipher   => 'Blowfish');
        my $strEncrypted = $cipher->encrypt($strValue);
        return MIME::Base64::encode_base64($strEncrypted);
    }
}

1;