#!/usr/bin/env perl

#   File:
#       Constants.pm
#
#   Description:
#       Contains the axolotl website API constants.
#
#   Version:
#       1.6.7
#
#   Date:
#       05.02.2013
#
#   Copyright:
#       Dr. Sergej Nowoshilow, Research institute of molecular pathology, IMP, Vienna

use strict;


package Constants;
{
    use constant ERR_OK                     => 0;
    use constant ERR_OK_BINARY              => -1;
    use constant ERR_METHOD_NOT_FOUND       => 1;
    use constant ERR_NOT_ENOUGH_PARAMETERS  => 2;
    use constant ERR_INVALID_PARAMETER      => 3;
    use constant ERR_MALFORMED_QUERY        => 4;
    use constant ERR_DATA_NOT_FOUND         => 5;
    use constant ERR_DB_ERROR               => 6;
    use constant ERR_ACCESS_DENIED          => 7;
    use constant ERR_RUNTIME_ERROR          => 8;
    use constant ERR_DATA_EXISTS            => 9;
    use constant ERR_METHOD_NOT_IMPLEMENTED => 10;
    
    use constant NT_ELEMENT => 1;                       # Node is an element
    use constant NT_ATTRIBUTE => 2;                     # Node is an attribute of the parent node
    use constant NT_TEXT => 3;                          # Node is a text node
    
    use constant UP_GUEST =>         0b00000000;        # Guest user: can only access the homepage and the registration page
    use constant UP_REGISTERED =>    0b00000001;        # Registered user: can view certain data
    use constant UP_COLLABORATOR =>  0b00000011;        # Collaborator user: can access the majority of pages and data with exception of data, which must be kept private to internal users only
    use constant UP_INTERNAL =>      0b00000111;        # Internal user: can access all data
    use constant UP_TESTER       =>  0b00001111;        # Tester: can view and use new tools
    use constant UP_ADMINISTRATOR => 0b11111111;        # Administrator: has full access
    
    use constant TD_ANNOTATION  =>    0x00000001;       # Transcript has annotation
    use constant TD_COVERAGE    =>    0x00000002;       # Transcript has Illumina reads mapping
    use constant TD_DOMAINS     =>    0x00000004;       # Transcript has annotated domains
    use constant TD_GENE        =>    0x00000008;       # Transcript belongs to a gene
    use constant TD_HOMOLOGS    =>    0x00000010;       # Transcript has RefSeq homologs
    use constant TD_ISH         =>    0x00000020;       # Transcript has ISH data
    use constant TD_LIBRARY     =>    0x00000040;       # Transcript has homologous library sequences
    use constant TD_MICROARRRAY =>    0x00000080;       # Transcript has mapped microarray probes
    use constant TD_ORF         =>    0x00000100;       # Transcript has an annotated ORF
    use constant TD_PARALOGS    =>    0x00000200;       # Transcript has paralogous sequences
    use constant TD_TIMECOURSE  =>    0x00000400;       # Transcript has timecourse data
    use constant TD_VERSIONS    =>    0x00000800;       # Transcript has homologous sequences in other assemblies
    
    use constant LSD_COVERAGE   =>    0x00000001;       # Library sequence has Illumina reads mapping
    use constant LSD_DOMAINS    =>    0x00000002;       # Library sequence has annotated domains
    use constant LSD_ISH        =>    0x00000004;       # Library sequence has ISH data
    use constant LSD_HOMOLOGS   =>    0x00000008;       # Library sequence has RefSeq homologs
    use constant LSD_LOCATION   =>    0x00000010;       # Library sequence has location (plate and well) information
    use constant LSD_MICROARRAY =>    0x00000020;       # Library sequence has mapped microarray probes
    use constant LSD_TIMECOURSE =>    0x00000040;       # Library sequence has timecourse data
    
    use constant MT_CONTACT => 1;                       # Message type: contact
    use constant MT_FEEDBACK => 2;                      # Message type: feedback
    use constant MT_BUGREPORT => 3;                     # Message type: bug report
    
    use constant BS_SUBMITTED => 'submitted';           # Blast job submitted
    use constant BS_PROCESSING => 'processing';         # Blast job is being processed
    use constant BS_FINISHED => 'finished';             # Blast job finished
    use constant BS_ERROR => 'error';                   # Blast job finished with error
    
    use constant DB_SRC_ASSEMBLY => 1;                  # Blast database: transcriptome assembly
    use constant DB_SRC_LIBRARY => 2;                   # Blast database: library
    use constant DB_SRC_COLLECTION => 3;                # Blast database: reads collection
    use constant DB_SRC_GENES => 4;                     # Blast database: genes collection
    use constant DB_SRC_GENOME => 5;                    # Blast database: genome assembly
    
    our @EXPORT_OK = ('ERR_OK',
                      'ERR_OK_BINARY',
                      'ERR_METHOD_NOT_FOUND',
                      'ERR_NOT_ENOUGH_PARAMETERS',
                      'ERR_INVALID_PARAMETER',
                      'ERR_MALFORMED_QUERY',
                      'ERR_RUNTIME_ERROR',
                      'ERR_DB_ERROR',
                      'ERR_ACCESS_DENIED',
                      'ERR_DATA_NOT_FOUND',
                      'ERR_DATA_EXISTS',
                      'ERR_METHOD_NOT_IMPLEMENTED',
                      
                      'NT_ELEMENT',
                      'NT_ATTRIBUTE',
                      'NT_TEXT',
                      
                      'UP_GUEST',
                      'UP_REGISTERED',
                      'UP_COLLABORATOR',
                      'UP_INTERNAL',
                      'UP_ADMINISTRATOR',
                      
                      'MT_CONTACT',
                      'MT_FEEDBACK',
                      'MT_BUGREPORT',
                      
                      'BS_SUBMITTED',
                      'BS_PROCESSING',
                      'BS_FINISHED',
                      'BS_ERROR',
                      
                      'DB_SRC_ASSEMBLY',
                      'DB_SRC_LIBRARY',
                      'DB_SRC_COLLECTION',
                      'DB_SRC_GENES',
                      'DB_SRC_GENOME',
                      
                      'TD_ANNOTATION',
                      'TD_COVERAGE',
                      'TD_DOMAINS',
                      'TD_GENE',
                      'TD_HOMOLOGS',
                      'TD_ISH',
                      'TD_LIBRARY',
                      'TD_MICROARRRAY',
                      'TD_ORF',
                      'TD_PARALOGS',
                      'TD_TIMECOURSE',
                      'TD_VERSIONS',
                    
                      'LSD_COVERAGE',
                      'LSD_DOMAINS',
                      'LSD_ISH',
                      'LSD_HOMOLOGS',
                      'LSD_LOCATION',
                      'LSD_MICROARRAY',
                      'LSD_TIMECOURSE');
}

1;