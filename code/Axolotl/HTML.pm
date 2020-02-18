#!/usr/bin/env perl

#   File:
#       HTML.pm
#
#   Description:
#       Contains the HTML module, which implements methods used to create HTML elements.
#
#   Version:
#       1.4.5
#
#   Date:
#       28.11.2012
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna


package HTMLelement;
{
    sub new
    {
        my ($class, $strTag, $refAttributes) = @_;
        $strTag = lc($strTag);
        my $self = {_tag => $strTag,
                    _isVoid => isVoid($strTag),
                    _class => $refAttributes->{class},
                    _id => $refAttributes->{id},
                    _innerHTML => $refAttributes->{content},
                    _style => "",
                    _attributes => {},
                    _children => [],
                    _events => {}};
        bless $self, $class;
        $self->addAttribute($_, $refAttributes->{attributes}->{$_}) foreach(keys %{$refAttributes->{attributes}});
        return $self;
    }
    
    sub isVoid
    {
        my $strTag = shift;
        return ($strTag eq 'area' ||
                $strTag eq 'base' ||
                $strTag eq 'br' ||
                $strTag eq 'col' ||
                $strTag eq 'command' ||
                $strTag eq 'embed' ||
                $strTag eq 'hr' ||
                $strTag eq 'img' ||
                $strTag eq 'input' ||
                $strTag eq 'keygen' ||
                $strTag eq 'param' ||
                $strTag eq 'source' ||
                $strTag eq 'track' ||
                $strTag eq 'wbr');
    }

    sub setInnerHTML
    {
        my ($self, $strInnerHTML) = @_;
        $strInnerHTML = "" unless defined($strInnerHTML);
        $self->{_innerHTML} = $strInnerHTML;
    }
    
    sub setStyle
    {
        my ($self, $strStyle) = @_;
        $self->{_style} = $strStyle if(defined $strStyle);
    }

    sub setClass
    {
        my ($self, $strClass) = @_;
        $self->{_class} = $strClass if(defined $strClass);
    }
    
    sub setID
    {
        my ($self, $strID) = @_;
        $self->{_id} = $strID if(defined $strID);
    }

    sub addAttribute
    {
        my ($self, $strName, $strValue) = @_;
        if((defined $strName) && (length($strName)>0) && (defined $strValue) && (length($strValue)>0))
        {
            $self->{_attributes}{$strName} = $strValue;
        }
    }
    
    sub addEvent
    {
        my ($self, $strEvent, $strCode) = @_;
        if((defined $strEvent) && (length($strEvent)>0) && (defined $strCode) && (length($strCode)>0))
        {
            $self->{_events}{$strEvent} = $strCode;
        }
    }
    
    sub appendChild
    {
        my ($self, $child) = @_;
        my @arrChildren = @{$self->{_children}};
        push(@arrChildren, $child);
        $self->{_children} = \@arrChildren;
    }
    
    sub getChildByID
    {
        my ($self, $strID) = @_;
        foreach(@{$self->{_children}})
        {
            return $_ if($_->{_id} eq $strID);
        }
        return undef;
    }
    
    sub generateHTML
    {
        my ($self, $strOffset) = @_;
        $strOffset = "" unless defined $strOffset;
        # Add attributes.
        my %hmAttributes = %{$self->{_attributes}};
        my $strAttributes = "";
        foreach my $strAttr (keys %hmAttributes)
        {
            $strAttributes .= " $strAttr=\"$hmAttributes{$strAttr}\"";
        }
        # Add style, class and ID.
        my $strStyle = (length($self->{_style})>0) ? " style=\"$self->{_style}\"" : "";
        my $strClass = (length($self->{_class})>0) ? " class=\"$self->{_class}\"" : "";
        my $strID = (length($self->{_id})>0) ? " id=\"$self->{_id}\"" : "";
        # Add events.
        my $strEvents = "";
        my %hmEvents = %{$self->{_events}};
        foreach my $strEvent (keys %hmEvents)
        {
            $strEvents .= " $strEvent=\"$hmEvents{$strEvent}\"";
        }
        # Add children.
        my @arrChildren = @{$self->{_children}};
        foreach my $child (@arrChildren)
        {
            $self->{_innerHTML} .= "\n" . $child->generateHTML("$strOffset\t");
        }
        # Tag content.
        my $strTagContent = $strAttributes . $strClass . $strID . $strEvents . $strStyle;
        my $strContent = "";
        # Void tag.
        if($self->{_isVoid})
        {
            $strContent = "$strOffset<$self->{_tag}$strTagContent />";
        }
        else
        {
            $strContent = "$strOffset<$self->{_tag}$strTagContent>$self->{_innerHTML}</$self->{_tag}>\n$strOffset";
        }
        #
        #
        #my $strContent = (length($self->{_innerHTML})>0 || length($strTagContent)>0) ? "$strOffset<$self->{_tag}$strTagContent>$self->{_innerHTML}\n$strOffset</$self->{_tag}>"
        #                                                                             : "$strOffset<$self->{_tag}$strTagContent />";
        return $strContent;
    }
}

package HTMLdocument;
{
    sub new
    {
        my ($class, $strTitle) = @_;
        my $self = {_title => $strTitle,
                    _meta_tags => {},           # meta_tag => content, e.g. "Author" => "CRTD"
                    _external_resources => [],  # array of external resources, e.g. href="style.css" rel="stylesheet" type="text/css"
                    _external_scripts => [],    # array of external scripts, e.g. type="text/javascript" src="script.js"
                    _styles => {},              # style => properties
                    _functions => [],           # array of strings representing one function each
                    _global_vars => {},         # variable => initial value (can be undef)
                    _body => new HTMLelement("body")};
        bless $self, $class;
        return $self;
    }
    
    sub setTitle
    {
        my ($self, $strTitle) = @_;
        $self->{_title} = $strTitle;
    }
    
    sub addMetaTag
    {
        my ($self, $strTag, $strContent) = @_;
        if((defined $strTag) && (length($strTag)>0) &&
           (defined $strContent) && (length($strContent)>0))
        {
            $self->{_meta_tags}->{$strTag} = $strContent;
        }
    }
    
    sub addExternalResource
    {
        my ($self, $strRelation, $strType, $strHREF) = @_;
        if((defined $strRelation) && (length($strRelation)>0) &&
           (defined $strType) && (length($strType)>0) &&
           (defined $strHREF) && (length($strHREF)>0))
        {
            my $strValue = "rel=\"$strRelation\" type=\"$strType\" href=\"$strHREF\"";
            my @arrLinks = @{$self->{_external_resources}};
            push(@arrLinks, $strValue);
            $self->{_external_resources} = [@arrLinks];
        }
    }
    
    sub addExternalScript
    {
        my ($self, $strType, $strSource) = @_;
        if((defined $strType) && (length($strType)>0) &&
           (defined $strSource) && (length($strSource)>0))
        {
            my $strValue = "type=\"$strType\" src=\"$strSource\"";
            my @arrScripts = @{$self->{_external_scripts}};
            push(@arrScripts, $strValue);
            $self->{_external_scripts} = [@arrScripts];
        }
    }
    
    sub addStyle
    {
        my ($self, $strName, $strAttributes) = @_;
        if((defined $strName) && (length($strName)>0) &&
           (defined $strAttributes) && (length($strAttributes)>0))
        {
            $self->{_styles}->{$strName} = $strAttributes;
        }
    }
    
    sub addGlobalVar
    {
        my ($self, $strName, $strValue) = @_;
        if((defined $strName) && (length($strName)>0) &&
           (defined $strValue) && (length($strValue)>0))
        {
            $self->{_global_vars}->{$strName} = $strValue;
        }
    }
    
    sub addFunction
    {
        my ($self, $strFunction) = @_;
        if((defined $strFunction) && (length($strFunction)>0))
        {
            my @arrFunctions = @{$self->{_functions}};
            push(@arrFunctions, $strFunction);
            $self->{_functions} = \@arrFunctions;
        }
    }
    
    sub getRootElement
    {
        my $self = shift;
        return $self->{_body};
    }
    
    # Creates a new HTML element.
    #   $refAttributes          hash reference holding the element attributes. Can have the following keys:
    #       - class             element class name. Can be undef
    #       - id                element ID. Can be undef
    #       - content           element content. Can be undef
    #       - attributes        reference to a hash, whereas hash keys are the attribute names and the values are attribute values
    sub createElement
    {
        my ($self, $strTag, $refAttributes) = @_;
        if((defined $strTag) && (length($strTag)>0))
        {
            return new HTMLelement($strTag, $refAttributes);
        }
        else
        {
            return undef;
        }
    }
    
    sub generateHTML
    {
        my ($self, $refParams) = @_;
        my $strDocument = "<!DOCTYPE html>\n";
        # Document header.
        $strDocument .= "<head>\n";
        $strDocument .= "<meta http-equiv=\"Content-Type\" content=\"text/html; charset=UTF-8\" />\n";
        # Meta tags.
        my %hmMetaTags = %{$self->{_meta_tags}};
        foreach my $strName (keys %hmMetaTags)
        {
            $strDocument .= "<meta name=\"$strName\" content=\"$hmMetaTags{$strName}\" />\n";
        }
        # External resources.
        my @arrLinks = @{$self->{_external_resources}};
        foreach my $strLink (@arrLinks)
        {
            $strDocument .= "<link $strLink />\n";
        }
        # External scripts.
        my @arrScripts = @{$self->{_external_scripts}};
        foreach my $strScript (@arrScripts)
        {
            $strDocument .= "<script $strScript ></script>\n";
        }
        # Title.
        $strDocument .= "<title>$self->{_title}</title>\n";
        # Styles.
        my $strStyles = "";
        my %hmStyles = %{$self->{_styles}};
        foreach my $style (keys %hmStyles)
        {
            $strStyles .= "$style {$hmStyles{$style}}\n";
        }
        $strDocument .= "<style type=\"text/css\">\n$strStyles</style>\n" if (length($strStyles)>0);
        # Scripts.
        my $strJS = "";
        my %hmVars = %{$self->{_global_vars}};
        foreach my $var (keys %hmVars)
        {
            my $val = $hmVars{$var};
            $strJS .= (defined $val) ? "var $var = $val;\n" : "var $var;\n";
        }
        $strJS .= "\n" if (length($strJS)>0);
        my @arrFunctions = @{$self->{_functions}};
        foreach my $fun (@arrFunctions)
        {
            $strJS .= "$fun\n";
        }
        $strDocument .= "<script>$strJS</script>\n" if (length($strJS)>0);
        $strDocument .= "</head>\n";
        $strDocument .= $self->{_body}->generateHTML("") . "\n</html>\n";
        return $strDocument;
    }
}

1;
