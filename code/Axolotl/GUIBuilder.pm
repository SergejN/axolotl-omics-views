#!/usr/bin/env perl

#   File:
#       GUIBuilder.pm
#
#   Description:
#       Contains the GUI builder module.
#
#   Version:
#       1.0.7
#
#   Date:
#       09.02.2014
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna


use strict;

package GUIBuilder;
{
    use constant GB_VIEWHEADER_SIMPLE => 0;
    use constant GB_VIEWHEADER_EXPANDABLE => 1;
    use constant GB_VIEWSTYLE_COLLAPSED => 0;
    use constant GB_VIEWSTYLE_EXPANDED => 1;
    use constant GB_WAITMSGSTYLE_HIDDEN => 0;
    use constant GB_WAITMSGSTYLE_VISIBLE => 1;
    
    use constant GB_LISTSTYLE_CHECKBOX => 0;
    use constant GB_LISTSTYLE_RADIO => 1;
    use constant GB_LISTSTYLE_NONE => 2;
    
    use constant GB_DDLISTSTATE_COLLAPSED => 0;
    use constant GB_DDLISTSTATE_EXPANDED => 1;
    
    use constant GB_BTNSTYLE_NORMAL => 0;
    use constant GB_BTNSTYLE_SUBMIT => 1;
    use constant GB_BTNSTYLE_CANCEL => 2;
    
    use constant GB_TBSTYLE_BUTTON => 0;
    use constant GB_TBSTYLE_FLAT => 1;
    
    use constant GB_LABELSTYLE_GREY => 1;
    use constant GB_LABELSTYLE_GREEN => 2;
    use constant GB_LABELSTYLE_YELLOW => 3;
    use constant GB_LABELSTYLE_ORANGE => 4;
    use constant GB_LABELSTYLE_RED => 5;
    
    our @EXPORT_OK = ('GB_VIEWHEADER_SIMPLE',
                      'GB_VIEWHEADER_EXPANDABLE',
                      'GB_VIEWSTYLE_COLLAPSED',
                      'GB_VIEWSTYLE_EXPANDED',
                      'GB_WAITMSGSTYLE_HIDDEN',
                      'GB_WAITMSGSTYLE_VISIBLE',
                      'GB_BTNSTYLE_NORMAL',
                      'GB_BTNSTYLE_SUBMIT',
                      'GB_BTNSTYLE_CANCEL',
                      'GB_TBSTYLE_BUTTON',
                      'GB_TBSTYLE_FLAT',
                      'GB_LISTSTYLE_CHECKBOX',
                      'GB_LISTSTYLE_RADIO',
                      'GB_LISTSTYLE_NONE',
                      'GB_DDLISTSTATE_COLLAPSED',
                      'GB_DDLISTSTATE_EXPANDED',
                      'GB_LABELSTYLE_GREY',
                      'GB_LABELSTYLE_GREEN',
                      'GB_LABELSTYLE_YELLOW',
                      'GB_LABELSTYLE_ORANGE',
                      'GB_LABELSTYLE_RED');

    # Creates a views container with views.
    #   Parameters:
    #       - $doc          reference to the HTML document object
    #       - $refViews     reference to the array containing the views.
    #                       Each array element must be a reference to a hash with the following keys:
    #                                   - title                 view title
    #                                   - description           view description
    #                                   - id                    view ID. Can be undef if type is GB_VIEWHEADER_SIMPLE
    #                                   - type                  either GB_VIEWHEADER_SIMPLE or GB_VIEWHEADER_EXPANDABLE. Default is GB_VIEWHEADER_SIMPLE
    #                                   - cbExpand              reference to a hash containing the details about the callback function. Ignored if type is GB_VIEWHEADER_SIMPLE. Must have the following keys:
    #                                       - name              name of the function to be called without the parentheses (e.g. Core.toggle). The first argument will be the reference to the header object
    #                                       - params            reference to an array containing any additional parameters to be passed to the callback function. Can be undef
    #                                   - style                 either GB_VIEWSTYLE_COLLAPSED (default) or GB_VIEWSTYLE_EXPANDED
    #                                   - anchor                anchor name. Can be undef
    #                                   - color                 color of the label displayed at the left hand border. Can be undef
    #                                   - infomsgID             ID of the infomsg element. Can be undef.
    #                                   - content               object representing the content of the viewarea. Can be undef.
    #                                   - toolbar               reference to a hash that specifies, which toolbar buttons should be displayed. Currently only can have following keys:
    #                                       - waitmsg           reference to a hash. If specified a wait icon is added. Can have following keys:
    #                                           - id            icon ID. Can be undef
    #                                           - state         the icon state. Can be either GB_WAITMSGSTYLE_HIDDEN (default) or GB_WAITMSGSTYLE_VISIBLE.
    #                                           - text          waitmsg text. Default is 'Loading...'
    #                                       - tools             reference to an array specifying additional functions that added to the toolbar. Each array element is a hashref with following keys:
    #                                           - name          item name
    #                                           - cbClicked     reference to a hash containing the details about the callback function, which is called when the item is clicked. Must have the following keys:
    #                                               - name      name of the function
    #                                               - params    any arguments to pass to the function. Can be undef
    sub createViewsContainer
    {
        my ($doc, $refViews) = @_;
        my $refContainer = {container => undef,
                            views => {}};
        my $viewsContainer = $doc->createElement('div', {class => 'views-container'});
        $refContainer->{container} = $viewsContainer;
        my $views = $doc->createElement('ul');
        foreach my $view (@{$refViews})
        {
            my $item = $doc->createElement('li');
            if($view->{anchor})
            {
                my $anchor = $doc->createElement('a', {id => $view->{anchor}});
                $item->appendChild($anchor);
            }
            my $datablock = $doc->createElement('div', {class => 'data-block'});
            $view->{color} = 'transparent' unless($view->{color});
            $datablock->setStyle("border-left: 5px solid $view->{color}");
            my $viewheader = $doc->createElement('div', {id => $view->{id},
                                                         class => 'view-header simple'});
            my $eventArea = $doc->createElement('div', {class => 'view-eventarea simple'});
            if($view->{type}==GB_VIEWHEADER_EXPANDABLE)
            {
                $eventArea->setClass('view-eventarea');
                if($view->{cbExpand})
                {
                    my @arrParams = ('this.parentNode');
                    push(@arrParams, @{$view->{cbExpand}->{params}}) if($view->{cbExpand}->{params});
                    $eventArea->addEvent('onclick', "$view->{cbExpand}->{name}(" . join(', ', @arrParams) . ")");
                }
            }
            my $viewtitle = $doc->createElement('div', {class => 'view-title'});
            my $title = $doc->createElement('span', {content => $view->{title}});
            $viewtitle->appendChild($title);
            $eventArea->appendChild($viewtitle);
            my $viewdescr = $doc->createElement('div', {class => 'view-description'});
            my $descr = $doc->createElement('span', {content => $view->{description}});
            $viewdescr->appendChild($descr);
            $eventArea->appendChild($viewdescr);
            $viewheader->appendChild($eventArea);
            if($view->{toolbar})
            {
                my $toolbar = $doc->createElement('ul', {class => 'view-toolbar'});
                # Waitbar
                my $waitmsg = $view->{toolbar}->{waitmsg};
                if(defined $waitmsg)
                {
                    my $infomsg = $doc->createElement('li');
                    $infomsg->setClass(($waitmsg->{state}==GB_WAITMSGSTYLE_VISIBLE) ? 'view-infomsg'
                                                                                    : 'view-infomsg hidden');
                    $infomsg->setID($waitmsg->{id}) if($waitmsg->{id});
                    $infomsg->setInnerHTML((defined $waitmsg->{text}) ? "<span>$waitmsg->{text}</span>"
                                                                      : '<span>Loading...</span>');
                    $toolbar->appendChild($infomsg);
                }
                # Tools
                my $tools = $view->{toolbar}->{tools};
                if(defined $tools)
                {
                    my $menu = $doc->createElement('li', {class => 'firstLevel',
                                                          content => '<span></span>'});
                    my @arrItems = @{$tools};
                    if(scalar @arrItems)
                    {
                        my $subMenu = $doc->createElement('ul', {class => 'secondLevel'});
                        foreach my $sm (@arrItems)
                        {
                            my $smItem = $doc->createElement('li', {content => "$sm->{name}"});
                            my $strArgs = join(', ', @{$sm->{cbClicked}->{params}}) if($sm->{cbClicked}->{params});
                            $smItem->addEvent('onclick', "$sm->{cbClicked}->{name}($strArgs);");
                            $subMenu->appendChild($smItem);
                        }
                        $menu->appendChild($subMenu);
                    }
                    $toolbar->appendChild($menu);
                }
                $viewheader->appendChild($toolbar);
            }
            $datablock->appendChild($viewheader);
            my $viewarea = $doc->createElement('div');
            $viewarea->setClass(($view->{style}==GB_VIEWSTYLE_EXPANDED) ? 'view-expanded'
                                                                        : 'view-collapsed');
            $viewarea->appendChild($view->{content}) if($view->{content});
            $datablock->appendChild($viewarea);
            $item->appendChild($datablock);
            $views->appendChild($item);
            $refContainer->{views}->{$view->{title}} = {item => $item, viewarea => $viewarea};
        }
        $viewsContainer->appendChild($views);
        return $refContainer;
    }
    
    # Creates a toolbar.
    #   Parameters:
    #       - $doc                      reference to the HTML document object
    #       - $refData                  reference to the hash containing the toolbar data with the following keys:
    #           - title                 Toolbar title
    #           - selected              name of the selected item
    #           - style                 either GB_TBSTYLE_BUTTON (default) or GB_TBSTYLE_FLAT
    #           - id                    toolbar ID. Can be undef
    #           - items                 reference to an array holding the toolbar items. Each array element must be a reference to a hash with the following keys:
    #               - title             item title
    #               - id                item ID. Can be undef
    #               - tooltip           tooltip. Can be undef
    #               - cbClicked         name of the callback function, which is called when the item is clicked
    #
    #   Remarks:
    #        If the item with the name specified by 'selected' does not exist, the first element will be selected.
    sub createToolbar
    {
        my ($doc, $refData) = @_;
        my $defaultItem = undef;
        my $list = $doc->createElement('ul', {id => $refData->{id}});
        $list->setClass(($refData->{style}==GB_TBSTYLE_FLAT) ? 'flattoolbar' : 'toolbar');
        my $item = $doc->createElement('li', {content => $refData->{title}});
        $list->appendChild($item);
        foreach my $btn (@{$refData->{items}})
        {
            my $item = $doc->createElement('li', {id => $btn->{id},
                                                  attributes => {title => $btn->{tooltip}}});
            my $ctrl = undef;
            if($refData->{style}==GB_TBSTYLE_FLAT)
            {
                my $span = $doc->createElement('span', {class => 'push-button'});
                $item->appendChild($span);
                $ctrl = $span;
            }
            else
            {
                $ctrl = $item;
            }
            $ctrl->setInnerHTML($btn->{title});
            $defaultItem = $ctrl if(($btn->{title} eq $refData->{selected}) || !$defaultItem);
            $ctrl->addEvent('onclick', "$btn->{cbClicked}");
            $list->appendChild($item);
        }
        $defaultItem->setClass(($refData->{style}==GB_TBSTYLE_FLAT) ? 'push-button pushed' : 'selected');
        return $list;
    }
    
    # Creates a button.
    #   Parameters:
    #       - $doc                      reference to the HTML document object
    #       - $refData                  reference to the hash containing the button data with the following keys:
    #           - text                  button text
    #           - tooltip               tooltip. Can be undef
    #           - style                 button style. Must be either GB_BTNSTYLE_NORMAL (default), GB_BTNSTYLE_SUBMIT or GB_BTNSTYLE_CANCEL
    #           - cbClick               name of the callback function, which is called upon click
    sub createButton
    {
        my ($doc, $refData) = @_;
        my $btn = $doc->createElement('span', {content => $refData->{text},
                                               attributes => {title => $refData->{tooltip}}});
        if($refData->{style} == GB_BTNSTYLE_SUBMIT)
        {
            $btn->setClass('button submit');
        }
        elsif($refData->{style} == GB_BTNSTYLE_CANCEL)
        {
            $btn->setClass('button cancel');
        }
        else
        {
            $btn->setClass('button');
        }
        $btn->addEvent('onclick', $refData->{cbClick});
        return $btn;
    }
    
    # Creates a label.
    #   Parameters:
    #       - $doc                      reference to the HTML document object
    #       - $refData                  reference to the hash containing the button data with the following keys:
    #           - text                  button text
    #           - tooltip               tooltip. Can be undef
    #           - id                    label ID. Can be undef
    #           - class                 custom label class. Can be undef
    #           - style                 button style. Must be one of GB_LABELSTYLE_* values or undef
    sub createLabel
    {
        my ($doc, $refData) = @_;
        my $label = $doc->createElement('span', {content => $refData->{text},
                                                 attributes => {title => $refData->{tooltip}}});
        my $strClass = 'label';
        if($refData->{style} == GB_LABELSTYLE_GREY)
        {
            $strClass .= ' label-grey';
        }
        elsif($refData->{style} == GB_LABELSTYLE_GREEN)
        {
            $strClass .= ' label-green';
        }
        elsif($refData->{style} == GB_LABELSTYLE_YELLOW)
        {
            $strClass .= ' label-yellow';
        }
        elsif($refData->{style} == GB_LABELSTYLE_RED)
        {
            $strClass .= ' label-red';
        }
        elsif($refData->{style} == GB_LABELSTYLE_ORANGE)
        {
            $strClass .= ' label-orange';
        }
        $strClass .= $refData->{class} if ($refData->{class});
        $label->setClass($strClass);
        $label->setClass($refData->{id}) if($refData->{id});   
        return $label;
    }
    
    sub createProgressBar
    {
        my ($doc) = @_;
        my $progressbar = $doc->createElement('div', {class => 'progressbar'});
        for(my $i=0;$i<5;$i++)
        {
            my $bar = $doc->createElement('div', {class => 'bar'});
            $progressbar->appendChild($bar);
        }
        return $progressbar;
    }
    
    # Creates a list.
    #   Parameters:
    #       - $doc                      reference to the HTML document object
    #       - $refData                  reference to the hash containing the list data with the following keys:
    #           - style                 list items style. Must be one of the following values:
    #                                       GB_LISTSTYLE_CHECKBOX (default)     list items are checkboxes
    #                                       GB_LISTSTYLE_RADIO                  list items are radio buttons
    #                                       GB_LISTSTYLE_NONE                   list items are text
    #           - groups                reference to an array holding the groups data. Each array element must be a hash reference with the following keys:
    #               - name              group name
    #               - toggle            reference to a hash with the following keys (can be undef, in which case no toggle item is displayed):
    #                   - title         toggle item title
    #                   - cbClicked     callback function, which is called when the item is clicked
    #               - items             reference to an array of group items. Each array element must be a reference to a hash with following keys:
    #                   - title         item title
    #                   - attributes    reference to hash containing additional attributes. Can be undef. Ignored if style is GB_LISTSTYLE_NONE
    #                   - description   item description. Can be undef.
    #                   - id            item ID. Reguired if style is either GB_LISTSTYLE_CHECKBOX or GB_LISTSTYLE_RADIOBTN
    #                   - name          item name. Required if style is either GB_LISTSTYLE_CHECKBOX or GB_LISTSTYLE_RADIOBTN
    #                   - cbChange      callback function, which is called when the item state is changed
    sub createList
    {
        my ($doc, $refData) = @_;
        my $list = $doc->createElement('div', {class => 'list'});
        my $groups = $doc->createElement('ul');
        foreach my $group (@{$refData->{groups}})
        {
            my $item = $doc->createElement('li');
            my $block = $doc->createElement('div');
            my $header = $doc->createElement('h2');
            $header->setInnerHTML($group->{name});
            $block->appendChild($header);
            my $elements = $doc->createElement('ul');
            foreach my $el (@{$group->{items}})
            {
                next if(!$el->{title});
                my $li = $doc->createElement('li');
                my $input = undef;
                my $label = undef;
                if($refData->{style} == GB_LISTSTYLE_NONE)
                {
                    $label = $doc->createElement('span', {class => 'itemlabel'});
                }
                else
                {
                    my $strType = ($refData->{style}==GB_LISTSTYLE_RADIO) ? 'radio' : 'checkbox';
                    $input = $doc->createElement('input', {attributes => {type => $strType, name => $el->{name}}});
                    $input->addEvent('onchange', $el->{cbChange}) if($el->{cbChange});
                    $input->setID($el->{id}) if($el->{id});
                    foreach my $strAttr (keys %{$el->{attributes}})
                    {
                        $input->addAttribute($strAttr => $el->{attributes}->{$strAttr});
                    }
                    $label = $doc->createElement('label', {class => 'itemlabel',
                                                           attributes => {for => $el->{id}}});
                }
                $li->appendChild($input) if($input);
                my $namespan = $doc->createElement('span');
                $namespan->setInnerHTML($el->{title});
                $label->appendChild($namespan);
                if($el->{description})
                {
                    my $descspan = $doc->createElement('span');
                    $descspan->setInnerHTML($el->{description});
                    $label->appendChild($descspan);
                }
                $li->appendChild($label);
                $elements->appendChild($li);
            }
            if($group->{toggle})
            {
                my $li = $doc->createElement('li', {class => 'toggleall'});
                $li->setInnerHTML($group->{toggle}->{title});
                $li->addEvent('onclick', $group->{toggle}->{cbClicked});
                $elements->appendChild($li);
            }
            $block->appendChild($elements);
            $item->appendChild($block);
            $groups->appendChild($item);
        }
        $list->appendChild($groups);
        return $list;
    }
    
    # Creates a drop-down list
    #   Parameters:
    #       - $doc                      reference to the HTML document object
    #       - $refData                  reference to the hash containing the list data with the following keys:
    #           - content               element representing the list content
    #           - title                 list title
    #           - id                    drop-down list ID. Can be undef
    #           - state                 initial state. Must be either GB_DDLISTSTATE_COLLAPSED (default) or GB_DDLISTSTATE_EXPANDED
    #           - cbClicked             callback function, which is called when the list title is clicked
    #           - buttons               reference to an array containing the buttons on the bottom of the list. Can be undef. Each element must be a reference to a hash with the following keys:
    #               - text              button text
    #               - tooltip           tooltip. Can be undef
    #               - style             button style. Must be either GB_BTNSTYLE_NORMAL (default) or GB_BTNSTYLE_SUBMIT
    #               - cbClick           name of the callback function, which is called upon click
    sub createDropDownList
    {
        my ($doc, $refData) = @_;
        my $strClass = ($refData->{state} == GB_DDLISTSTATE_EXPANDED) ? 'dropdown-list' : 'dropdown-list collapsed';
        my $ddlist = $doc->createElement('div', {class => $strClass, id => $refData->{id}});
        # Title.
        my $title = $doc->createElement('h3');
        $title->setInnerHTML($refData->{title});
        $title->addEvent('onclick', $refData->{cbClicked});
        $ddlist->appendChild($title);
        $ddlist->appendChild($refData->{content});
        if($refData->{buttons})
        {
            my $btnarea = $doc->createElement('div', {class => 'btnarea'});
            foreach (@{$refData->{buttons}})
            {
                my $btn = createButton($doc, $_);
                $btnarea->appendChild($btn);
            }
            $ddlist->appendChild($btnarea);
        }
        return $ddlist;
    }
}

1;