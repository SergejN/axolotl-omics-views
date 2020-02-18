#!/usr/bin/env perl

#   File:
#       webpage.pm
#
#   Description:
#       Contains the axolotl website builder module, which is used to create common page elements.
#
#   Version:
#       1.0.8
#
#   Date:
#       26.07.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna


use lib "/backend/modules";
use HTML;
use Constants;
use Mozilla::CA;

my $strHost = "https://www.axolotl-omics.org";

package Webpage;
{
    my @arrHeaderLinks = ({_topLevel => {_name => 'Home',
                                         _link => "$strHost/home"}
                          },
                          {_topLevel => {_name => 'Viewer'},
                           _secondLevel => [
                                             {_name => 'Assemblies',
                                              _description => 'View the detailed information on the available assemblies',
                                              _link => "$strHost/assemblies",
                                              _icon => "$strHost/images/header/assembly.png"},
                                             {_name => 'Datasets',
                                              _description => 'View the details and statistics on the available datasets',
                                              _link => "$strHost/datasets",
                                              _icon => "$strHost/images/header/dataset.png"},
                                             {_name => 'Libraries',
                                              _description => 'View additional libraries, such as EST or cDNA library',
                                              _link => "$strHost/libraries",
                                              _icon => "$strHost/images/header/library.png"},
                                             {_name => 'Collections',
                                              _description => 'View the collections of individual reads',
                                              _link => "$strHost/collections",
                                              _icon => "$strHost/images/header/collection.png"},
                                             {_name => 'Microarrays',
                                              _description => 'View available microarrays',
                                              _link => "$strHost/microarrays",
                                              _icon => "$strHost/images/header/microarray.png"},
                                             {_name => 'Search',
                                              _description => 'Search for contigs matching certain criteria',
                                              _link => "$strHost/search",
                                              _icon => "$strHost/images/header/search.png"}
                                           ]
                          },
                          {_topLevel => {_name => 'Blast',
                                         _link => "$strHost/blast"},
                           _secondLevel => [
                                             {_name => 'blastn',
                                              _description => 'Search for matches using a nucleotide query',
                                              _link => "$strHost/blastn",
                                              _icon => "$strHost/images/header/blastn.png"},
                                             {_name => 'megablast',
                                              _description => 'Search for very similar matches using a nucleotide query',
                                              _link => "$strHost/megablast",
                                              _icon => "$strHost/images/header/megablast.png"},
                                             {_name => 'dc-megablast',
                                              _description => 'Search for more distant matches using a nucleotide query',
                                              _link => "$strHost/dc-megablast",
                                              _icon => "$strHost/images/header/dc-megablast.png"},
                                             {_name => 'tblastn',
                                              _description => 'Search for matches using a protein query',
                                              _link => "$strHost/tblastn",
                                              _icon => "$strHost/images/header/tblastn.png"},
                                             {_name => 'tblastx',
                                              _description => 'Search for matches using a translated nucleotide query',
                                              _link => "$strHost/tblastx",
                                              _icon => "$strHost/images/header/tblastx.png"}
                                           ]
                          },
                          {_topLevel => {_name => 'Tools'},
                           _secondLevel => \&loadTools,
                          },
                          {_topLevel => {_name => 'Help'},
                           _secondLevel => [
                                             {_name => 'About',
                                              _description => 'View the general information about the project',
                                              _link => "$strHost/about",
                                              _icon => "$strHost/images/header/about.png"},
                                             {_name => 'FAQ',
                                              _description => 'Frequently asked questions about the website',
                                              _link => "$strHost/faq",
                                              _icon => "$strHost/images/header/faq.png"},
                                             {_name => 'Documentation',
                                              _description => 'View the developer documentation on how to access the data from a third-party applications',
                                              _link => "$strHost/documentation",
                                              _icon => "$strHost/images/header/documentation.png"},
                                             {_name => 'Bug report',
                                              _description => 'Send us feedback if you found any bug',
                                              _link => "$strHost/bug",
                                              _icon => "$strHost/images/header/bug.png"}
                                           ]
                          });

    @arrFooterLinks = ({_name => 'Home',
                        _link => 'home',
                        _subitems => [{_name => 'News',   _link => "$strHost/news"},
                                      {_name => 'RSS',    _link => "$strHost/rss"},
                                      {_name => 'Search', _link => "$strHost/search"}]},
                       {_name => 'Viewer',
                        _subitems => [{_name => 'Contig',           _link => "$strHost/search"},
                                      {_name => 'Assemblies',       _link => "$strHost/assemblies"},
                                      {_name => 'Datasets',         _link => "$strHost/datasets"},
                                      {_name => 'Libraries',        _link => "$strHost/libraries"},
                                      {_name => 'Transgenic lines', _link => "$strHost/transgenics"}]},
                       {_name => 'Blast',
                        _link => '/blast',
                        _subitems => [{_name => 'blastn',  _link => "$strHost/blastn"},
                                      {_name => 'tblastn', _link => "$strHost/tblastn"},
                                      {_name => 'tblastx', _link => "$strHost/tblastx"}]},
                       {_name => 'Help',
                        _subitems => [{_name => 'About',         _link => "$strHost/about"},
                                      {_name => 'FAQ',           _link => "$strHost/faq"},
                                      {_name => 'Documentation', _link => "$strHost/documentation"},
                                      {_name => 'Bug report',    _link => "$strHost/bug"},
                                      {_name => 'Impressum',     _link => "$strHost/impressum"}]});
    
    sub create
    {
        my ($strTitle, $strRSSLink) = @_;
        my $doc = new HTMLdocument($strTitle);
        addCommonResources($doc);
        addRSSLink($doc, $strRSSLink) if $strRSSLink;
        return $doc;
    }
    
    sub addCommonResources
    {
        my $doc = shift;
        # CSS.
        $doc->addExternalResource('stylesheet', 'text/css', 'https://fonts.googleapis.com/css?family=Source+Sans+Pro');
        $doc->addExternalResource('stylesheet', 'text/css', 'https://fonts.googleapis.com/css?family=Roboto+Condensed');
        $doc->addExternalResource('stylesheet', 'text/css', 'https://fonts.googleapis.com/css?family=Cutive+Mono');
        $doc->addExternalResource('stylesheet', 'text/css', "$strHost/css/general.css");
        $doc->addExternalResource('stylesheet', 'text/css', "$strHost/css/gui.css");
        $doc->addExternalResource('stylesheet', 'text/css', "$strHost/css/magnific-popup.css");
        $doc->addExternalResource('stylesheet', 'text/css', "$strHost/css/toastr.min.css");
        $doc->addExternalResource('stylesheet', 'text/css', "$strHost/css/jquery/jquery-ui.css");
        # JS.
        $doc->addExternalScript('text/javascript', "$strHost/js/core.js");
        $doc->addExternalScript('text/javascript', "$strHost/js/gui.js");
        $doc->addExternalScript('text/javascript', "$strHost/js/aomath.js");
        $doc->addExternalScript('text/javascript', "$strHost/js/aobio.js");
        $doc->addExternalScript('text/javascript', "$strHost/js/jquery/jquery-1.10.1.min.js");
        $doc->addExternalScript('text/javascript', "$strHost/js/jquery/jquery.magnific-popup.min.js");
        $doc->addExternalScript('text/javascript', "$strHost/js/jquery/jquery.toastr.min.js");
        $doc->addExternalScript('text/javascript', "$strHost/js/jquery/jquery-ui-1.10.3.custom.min.js");
        $doc->addExternalScript('text/javascript', "$strHost/js/jquery/jquery.color-2.1.2.min.js");
        $doc->addExternalScript('text/javascript', "$strHost/js/d3.v3.min.js");
        # Favicon.
        $doc->addExternalResource('shortcut icon', 'image/x-icon', "$strHost/images/favicon.ico");
    }
    
    sub addRSSLink
    {
        my ($doc, $strRSSLink) = @_;
        $doc->addExternalResource('alternate', 'application/rss+xml', $strRSSLink);
    }
    
    sub addCommonContent
    {
        my ($doc, $refParams, $strSelected, $bNoHeaderNav) = @_;
        $bNoHeaderNav = 0 unless defined $bNoHeaderNav;
        my $body = $doc->getRootElement();
        $doc->addFunction('$(document).ready(function () {$(document).tooltip();});');
        # Add header and top navigation bar.
        addHeader($doc, $body, $refParams, $strSelected, $bNoHeaderNav);
        # General page content.
        my $pagewrapper = $doc->createElement('div');
        $pagewrapper->setID('page-wrapper');
        $body->appendChild($pagewrapper);
        # Quick access panel
        my $qap = $doc->createElement('div', {id => 'quick-access'});
        $qap->setInnerHTML('&nbsp;');
        $pagewrapper->appendChild($qap);
        # Add an empty page content element.
        my $pageContent = $doc->createElement('div');
        $pageContent->setID('page-content');
        $pagewrapper->appendChild($pageContent);
        # Tools panel
        my $tp = $doc->createElement('div', {id => 'tools-panel'});
        $tp->setInnerHTML('&nbsp;');
        $pagewrapper->appendChild($tp);
        # Add footer.
        addFooter($doc, $body, $refParams);
        return $pageContent;
    }
    
    sub addHeader
    {
        my ($doc, $body, $refParams, $strSelected, $bNoHeaderNav) = @_;
        # Header.
        my $headerArea = $doc->createElement('div', {id => 'header'});
        my $headerInner = $doc->createElement('div', {id => 'header-inner'});
        my $logo = $doc->createElement('a');
        $logo->setID('header-logo');
        $logo->addAttribute('href', $refParams->{_base});
        my $img = $doc->createElement('img', {attributes => {src => "$strHost/images/header/logo.png",
                                                             width => '400',
                                                             height => '66',
                                                             alt => 'Axolotl transcriptome logo'}});
        $logo->appendChild($img);
        $headerInner->appendChild($logo);
        # User, search and navigation.
        my $hdrlinks = $doc->createElement('div', {id => 'header-links'});
        my $items = $doc->createElement('ul');
        # User
        my $item = $doc->createElement('li');
        $item->setInnerHTML('<div id="header-user">Welcome to the Axolotl-omics Docker container</div>');
        $items->appendChild($item);
        $hdrlinks->appendChild($items);
        $headerInner->appendChild($hdrlinks);
        # Search and navigation.
        $item = $doc->createElement('li');
        my $search = $doc->createElement('div', {id => 'header-search'});
        my $form = $doc->createElement('form', {attributes => {action => "$strHost/search",
                                                               method => 'get',
                                                               enctype => 'application/x-www-form-urlencoded',
                                                               name => 'searchterm'}});
        my $input = $doc->createElement('input', {attributes => {name => 'search',
                                                                 type => 'text',
                                                                 placeholder => 'Search...',
                                                                 name => 'query'}});
        $form->appendChild($input);
        $search->appendChild($form);
        $item->appendChild($search);
        # Header links.
        my $headernav = $doc->createElement('div', {id => 'header-nav'});
        my $list = $doc->createElement('ul');
        # Contact
        my $link = $doc->createElement('li');
        $link->setInnerHTML("<a href\"$strHost/contact\">Contact</a>");
        $list->appendChild($link);
        # Feedback
        $link = $doc->createElement('li');
        $link->setInnerHTML("<a href=\"$strHost/feedback\">Feedback</a>");
        $list->appendChild($link);
        
        # RSS feed.
        $link = $doc->createElement('li');
        $link->setInnerHTML("<a href=\"$strHost/rss\"><img src=\"$strHost/images/header/rss.png\" class=\"menu-icon\" alt=\"RSS feed\">RSS feed</a>");
        $list->appendChild($link);
        
        $headernav->appendChild($list);
        $item->appendChild($headernav);
        $items->appendChild($item);
        $headerArea->appendChild($headerInner);
        $body->appendChild($headerArea);
        addTopNav($doc, $body, $refParams, $strSelected) if(!$bNoHeaderNav);
    }
    
    sub addTopNav
    {
        my ($doc, $body, $refParams, $strSelected) = @_;
        my $topnav = $doc->createElement('div');
        $topnav->setID('topnav');
        # Inner.
        my $topnavInner = $doc->createElement('div');
        $topnavInner->setID('topnav-inner');
        my $list = $doc->createElement('ul');
        foreach my $item (@arrHeaderLinks)
        {
            # Get the minimal required privilege for the current item.
            my $strItemName = $item->{_topLevel}->{_name};
            my $canView = int($refParams->{_accessOpts}->getSetting(uc($strItemName), 'CanView'));
            if( (!$canView) || (($refParams->{_user}->{privilege} & $canView) == $canView) )
            {
                my $li = $doc->createElement('li');
                $li->setClass('selected') if($strSelected eq $strItemName);
                # First-level menu item
                my $title = undef;
                if(!$item->{_topLevel}->{_link})
                {
                    $title = $doc->createElement('span', {class => 'topnav-nolink'});
                }
                else
                {
                    $title = $doc->createElement('a');
                    $title->addAttribute('href', ($item->{_topLevel}->{_link} eq 'home') ? $refParams->{_base}
                                                                                         : "$item->{_topLevel}->{_link}");
                }
                $title->setInnerHTML($strItemName);
                $li->appendChild($title);
                # Second-level menu
                my $slm = $item->{_secondLevel};
                if($slm)
                {
                    $slm = $slm->($refParams) if(ref($slm) eq 'CODE');
                    my $ul = $doc->createElement('ul');
                    $ul->setClass('secondLevel');
                    foreach my $sli (@{$slm})
                    {
                        my $strSLIname = $sli->{_name};
                        $strSLIname =~ s/ /_/g;
                        $canView = int($refParams->{_accessOpts}->getSetting(uc($strItemName), $strSLIname));
                        if( (!$canView) || (($refParams->{_user}->{privilege} & $canView) == $canView) )
                        {
                            my $sl_li = $doc->createElement('li');
                            $sl_li->setInnerHTML("<h3><a href=\"$sli->{_link}\">$sli->{_name}</a></h3>".
                                                 "<div>$sli->{_description}</div>");
                            $ul->appendChild($sl_li);
                        }
                    }
                    $li->appendChild($ul);
                }
                $list->appendChild($li);
            }
        }
        $topnavInner->appendChild($list);
        $topnav->appendChild($topnavInner);
        $body->appendChild($topnav);
    }
    
    sub addFooter
    {
        my ($doc, $body, $refParams) = @_;
        my $footer = $doc->createElement('div');
        $footer->setID('footer');
        my $footerInner = $doc->createElement('div', {id => 'footer-inner'});
        # Footer logo.
        my $footerLogo = $doc->createElement('div', {id => 'footer-logo'});
        my $img = $doc->createElement('img', {attributes => {src => "$strHost/images/footer/logo-bottom.png",
                                                             width => '186',
                                                             height => '50',
                                                             alt => 'Axolotl transcriptome logo'}});
        $footerLogo->appendChild($img);
        # Copyright.
        my @arrTime = localtime(time);
        my $copyright = $doc->createElement('span', {id => 'copyright'});
        $copyright->setInnerHTML('&copy; 2012-'. ($arrTime[5]+1900) .' Sergej Nowoshilow<br />'.
                                 '<a href="http://www.imp.ac.at">&nbsp;&nbsp;&nbsp;&nbsp;IMP - Research institute of molecular pathology</a><br />');
        $footerLogo->appendChild($copyright);
        $footerInner->appendChild($footerLogo);
        # Footer navigation.
        my $iUserPrivilege = $refParams->{_user}->{privilege};
        my $nav = $doc->createElement('div', {id => 'footer-nav'});
        my $list = $doc->createElement('ul');
        foreach my $block (reverse @arrFooterLinks)
        {
            my $sectionItem = $doc->createElement('li');
            my $sectionList = $doc->createElement('ul');
            # Main item.
            my $mainItem = $doc->createElement('li');
            if(!$block->{_link})
            {
                $mainItem->setInnerHTML("<span>$block->{_name}</span>");
            }
            else
            {
                $mainItem->setInnerHTML("<a href=\"$block->{_link}\">$block->{_name}</a>");
            }
            $sectionList->appendChild($mainItem);
            # Subitems.
            my @arrSubitems = @{$block->{_subitems}};
            foreach my $si (@arrSubitems)
            {
                # Get the minimal required privilege for the current menu.
                my $strSI = $si->{_name};
                $strSI =~ s/ /_/g;
                my $subitem = $doc->createElement('li');
                $subitem->setInnerHTML("<a href=\"$si->{_link}\">$si->{_name}</a>");
                $sectionList->appendChild($subitem);
            }
            $sectionItem->appendChild($sectionList);
            $list->appendChild($sectionItem);
        }
        $nav->appendChild($list);
        $footerInner->appendChild($nav);
        $footer->appendChild($footerInner);
        $body->appendChild($footer);
    }
    
    sub loadTools
    {
        my ($refParams) = @_;
        my @arrItems = ();
        my $strToolsDir = '/frontend/tools';
        my @arrFiles = ();
        open(CMD_IN, "find $strToolsDir -name 'tool.xml' |");
        while(<CMD_IN>)
        {
            chomp($_);
            push(@arrFiles, $_);
        }
        close(CMD_IN);
        @arrFiles = sort @arrFiles;
        foreach my $strFile (@arrFiles)
        {
            my $xml = XML::Simple::XMLin($strFile, KeepRoot => 1, KeyAttr => []);
            my @arrPath = split(/\//, $strFile);
            pop(@arrPath); # Remove the filename
            my $strDir = pop(@arrPath);
            push(@arrItems, {_name => $xml->{tool}->{name},
                             _description => $xml->{tool}->{content},
                             _link => "/tools/$strDir",
                             _icon => ''});
        }
        return \@arrItems;
    }
}

1;
