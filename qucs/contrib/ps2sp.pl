#! /usr/bin/perl
#
# Copyright 2003/2004/2005/2006/2007 by Friedrich Schmidt <frie.schmidt@aon.at>
# Copyright 2000 by John Sheahan <john@reptechnic.com.au>
# Copyright 1996 by Andrew J. Borsa
#
# This is free software; you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation; either version 2, or (at your option)
# any later version.
# 
# This software is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
# 
# You should have received a copy of the GNU General Public License
# along with this package; see the file COPYING.  If not, write to
# the Free Software Foundation, Inc., 51 Franklin Street - Fifth Floor,
# Boston, MA 02110-1301, USA.  
#
#  derived from modified sources of :
#  Spiceprm version 0.11, Copyright (C) 1996 Andrew J. Borsa";
#  spicepp  version  1.5 2000/11/20 22:37:56 john Exp john $ ';
#######################################################################
#  ps2sp version 4.14 , Copyright(C) F.S. 2003/2004/2005/2006/2007
#  License: Terms of GNU-License
# ( special thanks to the work of John and Andrew )
#######################################################################
#  tested with Perl V 5.6.1 / Perl 5.8.8 / Tinyperl 2.0  with ps2sp.pl as perlscript and as binary file tinyperl -bin option
#  Debugger: Perl Debugger Ptkdb V1.1.0.91  TK V 800.023
#  last edited: 18.03.2007

#  Changelog: since 1.1.2005
#
#  03.01.2005 -h command line option added ( for help usage: ...)
#  07.01.2005 Variables in .pfunc expressions now all with paranthesis e.g. __1 to (__1) -> now some problems with
#             eval() are corrected;
#  08.01.2005 in func expand_parameters add lines to prevent .control till .endc to be expanded
#  14.01.2005 kill blanks in @(p)funcname, now search also for global .func in includefiles
#  17.01.2005 make the nested func algorithm more save ( check - differently - for : to much opened OR! to much
#             closed paranethesis )
#  31.01.2005 more paranthesis for all functions to make it save
#  01.02.2005 line 1902 in b-lines ** to ^ ( compatibility to ltspice )
#  01.02.2005 change predefined .funcs f(u()) instead of f(sgn())
#  02.02.2005 small changes in step parameter function oct, dec to handle better end-values
#  29.07.2005 support for relational operators in pspice syntax for b-sources,
#             (sub b_device_relational_op)
#             <,>,<=,>=,==,!=,&&,||,! -> converted to lt,gt,le,ge,eq,ne,and,or and not
#             binding of relop is strong ! -> 3+2<5 -> 3+(2<5)
#             if you want it other you can give paranthesis to the expr. (3+2)<5
#  31.07.2005 support for local funclines in subckt's
#             synchronization of .func to .pfunc to be compatible to pspice
#             (all .func defined lines are also automatically written as .pfunc lines !!)
#  01.08.2005 support for relational operators in pspice syntax for .funclines
#             (sub funcline_paramline_relational_op)
#             hint: relop in .paramlines are managed by perl itself
#  02.08.2005 support for multiple parameterstepping
#  04.08.2005 support for a<b?c:d op
#  06.08.2005 support for .probe expressions e.g.    .probe 3*v(2)+5 -> convert to spice3 plot 3*v(2)+5
#  20.12.2005 use Math::Trig included for trigonometric pfunc expressions
#             line 489 added in load_deck() s/^\*\$//; # *$ should be interpreted as a nutmeg commandline -> remove
#               *$ to enable it
#  24.12.2005 $param{"pi"}="3.1415"; $param{"e"}="2.718282";
#             $param{"echarge"}="1.602190e-019";$param{"kelvin"}="-2.73150e+002";
#             $param{"planck"}="6.626200e-034"; added
#  25.12.2005 if($anz!=$anz_pm[$i]) -> if($anz!=$panz_pm[$i]) in func eval_pfuncs();
#             support for *$ as nutmeg-command line prefix -> if detected at linestart -> deleted to enable
#             nutmeg cmd
#  26.12.2005 line 2635 changed from "foreach (@line)" to  "foreach (@_=@line)"
#             Some month ago I unfortunately deleted "@_=" from the expression above
#             Without "@_" the .param .func and .pfunc statements in @line are deleted
#             and therefore no local parameter or funclines for subcircuits worked any more !!!!
#             SORRY !!!
#  27.12.2005 modify function libinclude() to allow inline comments with ";" in continuation liblines ( lines
#             starting with + )
#             "$" for comment lines disabled !! (compatibility to nutmeg variables)
#             line 2260 changed to :  if ($_[0] =~ /^([0-9e\+\-\.]+)(t|g|meg|k|mil|m|u|n|p|f)?(v|a|s|f|ohm|h|w)?$/) {
#  12.01.2006 to allow xf xh xohm xw as additional unit x = m,u,meg ....
#  15.05.2006 corrected a small bug in the code for relational operators ">,<,>=,..." in b-device-relational-op
#             changed the value2b-device to allow "VALUE {}" statements in EFGH devices in additon to "VALUE = {}"
#  22.05.2006 r_device_tc=0,_0 added -> .model xxxxx R/RES (tc1=0 tc2=0  ) LINE 1448
#               or alternatively r1 1 2 {R*(1+tc1*({temp}-tnom)+tc2*({temp}-tnom)*({temp}-tnom))}
#  22.05.2006 pspice S,W device_device_.model xxx (I)VSWITCH to compatible xspice/spice3 device

#  25.05.2006 EXP()->e^() in b-lines
#  22.05.2006 STP(x) -> u(x) predefined function / (x>0?1:0) predefined pfunctions LINE 301/397

#  22.05.2006 eat blancs in .model-lines (XX = YY -> XX=YY) after parameterextraction
#  22.05.2006 TEMP in b-lines ($param{"temp"}="25"; ) LINE 204     .TEMP=Val OK ?
#  22.05.2006 15V -> 15 in b-lines  LINE1423

#  22.05.2006 small bug in expand_paralell -> corrected
#  01.06.2006 support for .tran TEND
#  01.06.2006 support for polynomial efgh-devices ( pspice and spice2 like )

#  02.06.2006 support for I/SDT() and DDT() pspice function ( integrate and differentiate )  in b-lines

#  03.06.2006 support for polynomial c and l  bdevice
#
#  03.06.2006 { operator NOT as ~(x) and XOR as (x)^(y) } -> b_device relational  ( works only with command line switch -xornot )
#
#  04.06-2006 better handling of commandlineswitches
#  09.06.2006 UNuse of math.trig  again ->    pi( ok) see 20.12.2005
#  10.06.2006 support for .dc PARAM name [OCT,DEC,LIST](LIN) 0 10 1 PARAM name [OCT,DEC,LIST](LIN) 0 1 0.1
#              (if no option is given defaults to LIN)
#  17.06.2006 support for C 1 0 q=val and L 1 0 flux=val expressions
#  21.06.2006 test under Linux -> done
#  23 06.2006 add paranthesis checker with command line switch
#             -check for b-lines and expressions
#  29.06.2006 user choosable subckt-postfix default = '_' ( global var = $spf )
#                   e^()  ->  EXP()  in b-lines to be pspice/ltspice compatible  ( ^ -> **)
#  30.06.2006 testsuite to avoid new errors
#  14.08.2006 added ln(x) and log10(x) to pfunctions
#  16.08.2006 debugmodus added : sub output_debug
#             commandlineswitch -debug to output
#             parameter , function and pfunction definitions to the cirfile
#  22.08.2006 added new function pwl_file and add_pwl_line to convert
#             asciifiles to spice-pwllines
#             syntax:  v1 1 0 pwl file='c:\usbsich\out2' var='v(2)'
#             fileformat: like generated by nutmeg with print col v(2) > out2
#             or print col v(1) v(2) .... > out2
#  23.08.2006 changes in some functions -> expand_parameters , process , skipnumber , expand_eqns
#             value2bdevice , prm_wr
#  24.08.2006 added support for resistor expressions
#             syntax: e.g. r1 1 0 value={expr}
#  03.09.2006 changed function neq(x) to ne(x) according to nutmeg syntax
#             some small bugfixes for special cases in skipnumber , value_2_bdevice , table2bh , table2bh_spice3 , poly_2_bdevic main_ctrl
#             redesign of functions process,expand_parameter and expand_eqn -> now faster and more readable
#  05.09.2006 corrected default values for VSWITCH/ISWITCH device if not given on .model line
#  07.09.2006 new predefined functions buf,inv for compatibility to ltspice
#             also new pfunctions u,buf,inv,uramp
#             corrected a bug synchronizing func and pfunc lines which only worked if count
#             of func and pfunc lines was equal -> now works like expected
#             changed some predefined function definition to be compatible to winspice, ltspice and nutmeg
#  08.09.2006 more errorchecking : sub process() -> if expression evaluation fails -> warning and exit
#             but perl unfortunately is very error tolerant
#  12.09.2006 user manual for the gui ( preprocessor_gui.pl )
#  17.09.2006 corrected a bug in table2bh code ( no space between first and second and last and before last value )
#  01.10.2006 now .lib also includes devicemodels ( not only subcircuits like before ) and blanks in filenames work now
#             .inc or .include also work with blanks in the filename
#  02.10.2006  tool to generate .nodeset lines from transient,dc or op ascii-ouputfile
#             .savebias (-op|-tran) (-timepoint=val) infile outfile
#             .loadbias infile (like include)
#  26.10.2006 changes in prm_scan , prm_wr  to allow parametrized x-line calling in subcircuits for more than one level
#             changes in prm_scan , prm_wr to allow
#             all subcktparamters , local parameters,function,pfunctions now have the suffix _xname
#             xname is the name of the subcircuit where the variables are defined !!!
#  31.10.2006 correct a big BUG in the parameter evaluation subroutine "process" s/\b$key\b/$val/g -> s/\b$key\b/\($val\)/g
#             now all expressions are substituted with implicit paranthesis around
#  05.11.2006 NEW ps2sp.pl V4.0 : now the subcircuit parameter code is completely rewritten to allow parametrized
#             subcircuits of any level (new file )
#             add support for functions as subcircuit parameters :params a={2*fu(p1,p2*3)}
#             change of join,split(',') to join,split(';') since ',' is a parameter delimiter in functions f(,,)
#  07.11.2006 add debug information for all unique parameterized subcircuits to the intermediate file "sub.tmp"
#             to check the parameter substitution and unique subcircuit generation
#  11.11.2006 adapt .lib code to handle nested parametrized subcircuits
#             correct a bug in .inc code to handle correctly nested inc's
#  16.11.2006 some enhancements in the nested function and parameterexpansioncode and the libexpansioncode
#             extensive testing with various pspice source files with .lib and nested subcircuits
#             copyright message , date , time , filename and used options added to second line of converted cirfile
#             bugfix in function table2bh_spice3 , new commandlineoptions : -tosub -tolib -fromsub -fromlib
#  19.11.2006 enhance pspice compatibility ( delete surplus + for continuation lines in value2bdevice ),
#             rewrite of .global node expansion code -> virtual node 'times' always global ,
#             enhance paranthesis checker ( called now 3 times )
#             small changes in V/ISWITCH model ($lm=log(($ron*$roff)**0.5);) ,
#             changes in function &process
#  21.11.2006 some cosmetic ( rearranging of functions )
#
#  24.02.2007 handle a bug (about line 2889) in xline params code if cidx=-1 (called from main):
#             e.g. xline ... params: m={m} should not give variable recursion error message and quit the program
#             and also rhs version of 'm' should not be changed to 'm_nbr'
#             because rhs 'm' is a global parameter !
#             therefore the correspondent codelines are added to the if(cidx>=0) {..} part
#  15.03.2007 new function atan2(y,x) added (4 quadrant phase output -pi...pi )
#             this function is present in perl (.funcline) but not in standard spice3 (b-line)

#  ?? ?? ???? conversion of .step param SPICEPARAM .. to equivalent nutmeg script ( parameter-analysis loop )
#             SPICEPARAM maybe:  @devicename[param]=val or @@modelname[param]=val @@@global=val

# still to do :

#  ??.??.2006  usermanual
#  ??.?.2006   software-documentation
#  ??.?.2006   better outputformat handling with more switches
#             ( -winspice -superspice -vspice -spoV203 -spoV222 -ltspice -sp3 -ngspice
#             which contains each a certain amount of their own subswitches )
#
#######################################################################################################################################
# HINT: if you suspect the preprocessor to give erroneous results -> check the intermediate preprocess files
#        "sub.tmp" and "lib.tmp"
# HINT: if the converter never returns check the equivalence of opened and closed paranthesis in expressions ( -check command line option )
# HINT: to check if the parameterevaluation and the function expansion is correct use command line switch -debug
#######################################################################################################################################
# usage: ps2sp (options) inputfile.cir > outputfile (with the compiled version -> tinyperl -bin )
#    or  perl ps2sp.pl (options) inputfile.cir > outputfile (with perl installed)
#    or  tinyperl ps2sp (options) inputfile.cir > outputfile (with tinyperl installed)
#
# options:
#        -h displays the help screen
#        -sp3 switch means conversion of pspice table to spice 3 b-source instead of xspice core model ( default )                    #
#        -ltspice switch means conversion of ^ spice 3 power to ** ltspice power and addition of tripdv=1 tripdt=1 in b-lines         #
#        -notinylines produces longer b-lines for some functions ( default is tinylines = shorter b-lines )
#        -check determine the same count of open and closed paranthesis in b-lines ( default is nocheck )
#        -xornot allows ^ and ~ operators in the netfile (don't mix with ^ as power operator)
#                use the ** operator as power instead
#        -debug for debugging all .param .func and .pfunc defintions ( default is nodebug )
#        -tosub only output subckt expansions
#        -tolib only output lib expansions
#        -fromsub inputfile is a sub.tmp file
#        -fromlib inputfile is a lib.tmp file
#######################################################################################################################################

$MAXLEN = 100;      # Max output line length for output.
$DMAXLEN = 10;      # Amount to increment of $MAXLEN if necessary.
$wrap=100;          # if more than 150 chars -> wrap lines


# ps2sp.pl command line switches
$tinylines=1; # cmdlineswitch notinylines to disable tinylineexpansion
$spice3=0; # default pspice table model to xspice core model conversion
$ltspice=0; # default
$xornot=0; # default ( command line switch -xornot -> enables ~ and ^ expressions )
$check=0; # default ( paranthesis checker enabled with -check command line switch )
$debug=0; # output all parameters and functions
$fromsub=0; # continue from sub.tmp
$fromlib=0; # continue from lib.tmp
$tosub=0; # stops after generation of lib.tmp and sub.tmp
$tolib=0; # stops after generation of lib.tmp
# command line switches

$tnom=27; # spice nominal temperature

# parameterpostifx for unique parameternames ( var1 -> var1_1 .. _2 _3 _4 .... )
$parampostfix='_';
 # subnamepostfix for unique subnames ( subname ->  subname_1 .. _2 _3 _4 ..... )
$spf='_';
# note: ( postfix should not be a perl wordlimiter in order to perl regex \b - option works fine

# variables for .probe lines and .step parameterstepping lines
@vec=(); # stores all traces to plot (.probe lines)
$step=0; # default no parameterstepping found
@steparray=(); # all stepped values
@stepparams=(); # name of the stepparam
@stepparamcnt=(); # cnt of param values of each stepparam
$probelines=0; # how much .probe lines detected
@probe=(); # where to store probelines
@analtype=("op","dc","ac","tran"); # which analtype is used in the .step line
$anal=0; # default is op

@control=(); # where to store controllines

@deck=(); # where to hold all lines of the actual inputfile

$infile;   # the actual inputfile ( xxx.cir or lib.tmp or sub.tmp )
$inputcirfile; # the name of the original cirfile from the commandline

# spice units
%units = ('f','1e-15','p','1e-12','n','1e-9','u','1e-6','mil','25.4e-6',
    'm','1e-3','k','1e3','meg','1e6','g','1e9','t','1e12');
$* = 1;     # perl parameter Pattern match with multi-line strings. ---------- deprecated

# global vars for user defined pspice functions , pfunctions , parameters
%param=();     # global Parameter hash for .param and params: lines
$fidx=();      # index of user defined .func lines @funcname, @anz_pm , @expr
$pfix=();      # index of user defined .pfunc lines @pfuncname, @panz_pm , @pexpr
@funcname=();  # names of user defined function names
@pfuncname=(); # names of user defined pfunction names
@anz_pm=();    # parametercount of user defined functions
@panz_pm=();   # parametercount of user defined pfunctions
@expr=();      # rhs of function = expression
@pexpr=();     # rhs of pfunction = expression
%globals=();   # hash for .global lines ( global nodes )

################################### M A I N #############################################
#########################################################################################

&initialize_predefined_parameter_functions; # initialize global parameters , functions
&getargs(); # get switches from the ps2sp.pl command line
&first_stage; # subcircuit expansion , savebias , loadbias , .lib , .inc

open (INFILE,$infile) || die "Can't open source file sub.tmp : $infile\n";
  $_=<INFILE>;chop;@deck="" . $_;   # heading/comment line passthrough

&second_stage; # controllines , .step line , global nodes , expand variable TIME , manage pwl_file
# normally one loop , more loops if .step present
# convert all other lines , expand parameters , expand functions
&main_ctrl;
close(INFILE);

################################### M A I N #############################################
#########################################################################################

#
sub first_stage {

local(%sub,%subcall_all,%subcall_sub,%subcall_root,%subcall,%sub_prm,%subckt);
local(%sub_lprm,%sub_lfunc,%sub_lpfunc);
local($ref_prmval,$ref_pprmval,$ref_funcprmval,$ref_pfuncprmval);
local($max,$linenum);

# %sub;          # all x-lines with parameters from the original deck and their parameters (%subcall and %subcall_root)
# %subcall_all;  # all unique subckts with parameters to be generated  (generated from %subcall and %subcall_root)
# %subcall_sub;  # x-lines called from inside subckts
# %subcall_root; # x-lines called from the root level
# %subcall;      # %subcall_sub + %subcall_root
# %sub_prm;      # all .subckt parameters from the original deck
# %subckt;       # all .subckt lines (only if parametrized) from the original deck

# %sub_lprm;     # all local .param statementes from all entries in %subckt
# %sub_lfunc;    # all local .func statementes from all entries in %subckt
# %sub_lpfunc;   # all local .pfunc statementes from all entries in %subckt

# $ref_prmval;   # reference to .subckt parameter from a specific entry in %subckt
# $ref_pprmval;  # reference to local .param statements from a specific entry in %subckt
# $ref_funcprmval; # reference to local .func statements from a specific entry in %subckt
# $ref_pfuncprmval; # reference to local .pfunc statements from a specific entry in %subckt

# local $max;            # global unique identifier counter for all x-lines with parameters in the circuit
# local $linenum;

  if(!$fromsub) {
    if(!$fromlib) {
      $inputcirfile=$infile=$ARGV[0]; # infile = $ARGV[0]   outfile = lib.tmp
      open(INFILE, $infile) || die "Can't open input source file: $infile\n";
      $_=<INFILE>;chop;@deck="" . $_;   # heading/comment line passthrough
      &read_deck;
      $deck[0]=~s/(^[^\*].*)/\*$1/; # first line should be with *
      if($ltspice) {&do_ltspice;}
      ############
      &savebias; # new for saving op or transient data to .nodeset file
      &loadbias; # new for loading .nodeset files to the deck
      ##############
      &expand_incs;#
      &expand_libs;#
      ##############
      $dateiname="lib.tmp";
      &fprintdeck; # prints to lib.tmp
      close(INFILE);
      if($tolib) {exit;}
      #  local .param = , default .subckt params , xline params
      $infile="lib.tmp";
    }
    else {
      $infile=$inputcirfile=$ARGV[0];
    }
    $outfile="sub.tmp";
    open(INFILE, $infile) || die "Can't open lib.tmp source file: $infile\n";
    ############ handles of subckt's parameters and subckt modelfiles
    &prm_scan; #
    ############
    close(INFILE);
    open(INFILE, $infile) || die "Can't open lib.tmp source file: $infile\n";
    #unlink $outfile if $#ARGV;
    open(OUTFILE,"+>$outfile") || die "Can't open sub.tmp output file: $outfile\n";
    ##########
    &prm_wr; #
    ##########
    close(INFILE);
    close(OUTFILE);
    if($tosub) {exit;}
    $infile = "sub.tmp"; # outfile = STDOUT
  }
  else { # from_sub
    $inputcirfile=$infile=$ARGV[0];
  }
}
sub second_stage {
  my($options,$infoline,$date,$copyright);

  &read_deck; # whole deck read in @deck variable
  $date=localtime;
  $infoline="* infile=$inputcirfile date=$date Converted with ps2sp.pl V4.14 ";
  $options="* options: -sp3=$spice3 -ltspice=$ltspice -fromsub=$fromsub -fromlib=$fromlib -check=$check (tinylines=$tinylines)";
  $copyright="* copyright 2007 by Friedrich Schmidt - terms of Gnu Licence ";
  splice(@deck,1,0,$infoline,$options,$copyright);
  &read_stepparams; # if .step detected -> $step=1 .step param paramname (lin,oct,dec,list) ......
  &read_controllines; # read all controllines into @control;
  if($check) {&check;}
  # new what can be done only once also for multiruns
  &pwl_file;      # new command for pwl source line loaded from a file
  &time2vtime;    # if .tran analysis ->  add a pwl source with a node v(times) -> (compatibility with pspice TIME )
  &read_globals;  # read in global node lines .global in %globals
  &expand_globals; # add global nodes in every (because of nested subckts) .subckt and x-line
}
sub main_ctrl { # is there one run or are there multiple runs - this main routine calls all other routines
  my ($done,@copydeck,$i);
  local (@aktstepparam,$runs);
  #$memidx=0; #  for synchronization of func lines with pfunc
  #$memidx2=0;
  if($step >= 1) { # parameterstep found -> one .step xxx line is present in deck
    $runs=0;
    $step--; # now as idx for arrays
    @copydeck = @deck; # save it for reinit
    $done=0;
    #@aktidx=(0,0,-1);
    for($i=$step;$i>=0;$i--) {$aktidx[$i]=0;} # set zero
    $aktidx[($step)]=-1; # lsb
    while(!$done) {
      # compute aktidx[$i]
      $aktidx[($step)]++; # now (0,0,0)
      for($i=$step;$i>=0;$i--) {
        if($aktidx[$i]>=$stepparamcnt[$i]) {
           if($i>0) {
              $aktidx[$i]=0; # reset and
              $aktidx[$i-1]++;  # carry
           }
           if($aktidx[0]==$stepparamcnt[0]) {$done=1;goto leave;} # overflow
        }
      }
      # compute aktstepparam[$i]
      for($i=$step;$i>=0;$i--) {
            $aktstepparam[$i]=$stepmat[$i][$aktidx[$i]]; # actual stepparam values
      }
      @deck = @copydeck;
      $runs++; # number of run
      #################################
      &manage_all_devicelines($step);
      #################################
      $dateiname = &pp_("x".$runs,$inputcirfile);
      &fprintdeck; # save
    }
    leave:
    # now output of the main controlling file to stdout
    # this file with its .control  .. .endc statements starts all genearted cirfiles
    &output_controlfile_stdout;
  } # ende if step
  else  { # only one RUN ( normal case ) nothing to plot or ltspice mode
      ###########################
      &manage_all_devicelines(-1);
      ###########################
      &printdeck;
  }
}
sub output_controlfile_stdout {
    my($n,$i,$k,$tmp,$tp,$cnt,@temp,$trace,$w,$scalevec,$steps,@plotlines,@crosslines);

    print "* this ist the main control file for parameterstepped circuits";
    print "\n.control";
    print "\ndestroy all";
    for ($n=1;$n<=$runs;$n++) {
       # source in each file with a unique stepparam
       $tmp=&pp_("x".$n,$inputcirfile);
       $tmp=&quotes($tmp);
       print "\nsource $tmp";
    }
    print "\n.endc\n";
    # plot vectors analysis for all runs
    # only plot for .tran analysis !!
    # .probe v(1) v(2) -> plot tran1.v(1) tran2.v(1) tran3.v(1) tran1.v(2) tran2.v(2) tran3.v(2)
    if($anal>0) { # tran and ac-dc
       $tp=$analtype[$anal];
       print "\n.control";
       for ($i=0;$i<$probelines;$i++) { # for all probelines
          $cnt=@temp=split(/\s+/,$vec[$i]); # for all traces in actual probeline
          $plotlines[$i]="plot ";
          foreach $trace (@temp) {
             for($k=1;$k<=$runs;$k++) {
                 $plotlines[$i]=$plotlines[$i].$tp.$k.".".$trace." ";
             }
          }
          print "\n$plotlines[$i]";
       }
       print "\n.endc";
    }
    else { #  ($anal==0) # = op parameterstepping
       # first collect all crosslines for the .control ... .endc statements
       $w=-1;@crosslines=();
       for ($i=0;$i<$probelines;$i++) { # for all probelines
          $cnt = @temp = split(/\s+/,$vec[$i]); # for all traces in actual probline
          for ($j=0;$j<$cnt;$j++) {
             $w++; # tracecounter -> one crossline per trace
             $crosslines[$w]="cross ".$temp[$j]." 0 ";
             for ($k=1;$k<=$runs;$k++) { # for all runs
                $crosslines[$w]=$crosslines[$w]."op".$k.".".$temp[$j]." ";
             }
          }
       }
       # now prepare all plotlines for the .control .endc statements
       @plotlines=();
       for ($i=0;$i<$probelines;$i++) { # for all probelines
          $plotlines[$i]="plot ";
          $cnt = @temp = split(/\s+/,$vec[$i]); # for all traces in actual probline
          foreach $trace (@temp) {
             $plotlines[$i]=$plotlines[$i].$trace." ";
          }
       }
       # now prepare new scalevector = parametervector
       $scalevec="cross step 0 ";
       foreach $steps (@steparray) {
           $scalevec=$scalevec.$steps." ";
       }
       # now put all together
       print "\n.control";
       print "\nsetplot const";
       for ($i=0;$i<=$w;$i++) { # for all traces
          print "\n$crosslines[$i]";
       }
       print "\n$scalevec";
       print "\nsetscale step";
       for ($i=0;$i<$probelines;$i++) { # for all traces
          print "\n$plotlines[$i]";
       }
       print "\n.endc\n";
    }
    print "\n.end\n";
}
sub read_deck {
my ($lnr);

  while (<INFILE>) {
     chomp; # chomp is better than chop -> last line .end -> .en error
     # dont lowercase stuff in quotes
     $lnr = $.; # act. linenumber
     if( not $lnr eq 1 ) { # let the first line unchanged
         if (/(.*)([\'\"])(.*)([\"\'])(.*)/) {
              $_=lc($1) . $2 . $3 . $4 . lc($5);
         }
         else { $_ = lc($_); }
         s/^\*\$//; # *$ should be interpreted as a nutmeg commandline -> remove *$ to enable it
         s/\;.*//; # no inline comments with ;
         s/^\*.*//;  # no comments starting with *
         s/\s\s+/ /g; # shrink multiple whitespaces
         s/^\s*//; # trim leading whitespaces and delete blanc lines
         if (/^\s*\+(.+)/) {$_ = pop (@deck) . " " . $1;} # continuation line
     }
     push @deck,$_ if (length($_) >0);
  }
}
sub manage_all_devicelines {
  my($mystep)=$_[0]; # the actual step 0,1,2  (-1 if no .step command present)
  my $i;
  local ($memidx,$memidx2);

    $memidx=0; #  for synchronization of func lines with pfunc
    $memidx2=0;

    if(!$ltspice) {&poly_2_bdevice;}
    &value2bdevice;
    &r_expressions;
    &cl_expressions;
    &b_device_sdt_idt;
    &b_device_relational_op;
    &funcline_paramline_relational_op;
    &fix_temp; # .temp=25 instead of .options temp=25
    if($spice3) { &model_r_spice3; }
    elsif(not $ltspice) {&model_r;}
    if(not $ltspice) {&model_switch;}
    if($spice3) {&table2bh_spice3;} # if pspice like efgh TABLE source is present convert it to spice b-source models
    else {&table2bh;} # not spice3 - if pspice like efgh TABLE source is present convert it to xspice core model
    &read_funcs;
    &read_pfuncs;
    if($check) {&check;}
    &eval_funcs;
    &eval_pfuncs;
    &expand_funclines;
    &expand_pfunclines;
    &read_probelines;
    &read_parameters;
    for($i=$mystep;$i>=0;$i--) {
       $param{$stepparams[$i]}=$aktstepparam[$i]; # update parameterlist with actual .step param value
    }
    if($check) {&check;}
    &eval_parameters;
    if($debug) {&output_debug;}
    &expand_parameters;
    &expand_parallel;
    if(not $ltspice) {&expand_control;}
}
sub read_stepparams {
  my ($n,$cnt,$stepstart,$stepstop,$stepsize,$val,$rest);
  local ($i); # parameter i also available for the subroutines dec,lin,log,list,oct

  $step=0;
  for ($i=0;$i<@deck;$i++) {   # for the whole deck
     $_=$deck[$i];
     if(m/^\.op\b/i || m/^op\b/i) {$anal=0;} # .op or op and not .op(tions)
     elsif(m/^\.ac\b/i || m/^ac\b/i) {$anal=2;} # .ac or ac
     elsif(m/^\.tran\b/i || m/^tran\b/i) {$anal=3;} # .tran or tran
     # .step param paramname [oct|lin|dec|list] values
     elsif(m/^\.step/i) {
       $step++;
       @steparray=();
       if (m/oct/i) {($stepparam,$cnt)=&step_oct;}
       elsif (m/dec/i) {($stepparam,$cnt)=&step_dec;}
       elsif (m/list/i) {($stepparam,$cnt)=&step_list;}
       else {($stepparam,$cnt)=&step_lin;}  # must be lin !
       splice(@deck,$i,1,"* Parameterstepping variable=$stepparam detected");
       eval('@temp'."$step".'=@steparray;');
       eval('$stepmat[($step-1)]=\@temp'."$step;");
       push(@stepparams,$stepparam);
       push(@stepparamcnt,$cnt);
     }
       # .dc { param paramname [oct,lin,dec,list] values } {param paramname [oct,lin,dec,list] values } ........
       # translated to on .op line and multiple .step lines
       # .op
       # .step { param paramname [oct,lin,dec,list] values }
       # .step { param paramname [oct,lin,dec,list] values }
       # ........................
     elsif(m/^\.dc/i && m/param/i) { # parameterstepping as .dc command
       $anal=0;                        #  from { param paramname [oct,lin,dec,list] values  }  { param paramname [oct,lin,dec,list] values  }
       s/param/#/g;	             #  to    {      #  paramname  [oct,lin,dec,list] values }  {      # paramname  [oct,lin,dec,list] values }
       while(s/\#([^\#]+)//) { # cut one statement from # to # and substitute it with one .step line
           splice(@deck,$i+1,0,".step param $1"); #
       }
       splice(@deck,$i,1,".op"); # substitute the original  .dc .. param ... line with .op line
     }
     elsif(m/^\.dc/i || m/^\bdc\b/i) {$anal=1;} # .dc or dc -> have to be after .dc + param
     else {}
  }
}
# param paramname oct start stop size
sub step_oct {
   my($n,$m,$stepparam,$stepstart,$stepstop,$stepsize);

   if($deck[$i]=~s/param\s+(\S+)\s+\boct\b\s+(\S+)\s+(\S+)\s+(\S+)//i) {
       $stepparam = $1; # global defined
       $stepstart = &unit($2);
       $stepstop = &unit($3);
       $stepsize = &unit($4);
   }
   if($stepstart<=0) {$stepstart=1e-9;}
   $n=$stepstart;
   $m=0;
   while($n<$stepstop) {
       if($n eq $stepstop) {last;}
       $steparray[$m]=$n;
       $n=$stepstart*(2**(1/$stepsize))**($m+1);
       $m++;
   }
   $steparray[$m]=$stepstop; # last element
   return ($stepparam,$m+1);
}
# param paramname oct start stop size
sub step_dec {
  my($n,$m,$stepparam,$stepstart,$stepstop,$stepsize);

  if($deck[$i]=~s/param\s+(\S+)\s+\bdec\b\s+(\S+)\s+(\S+)\s+(\S+)//i) {
    $stepparam = $1;
    $stepstart = &unit($2);
    $stepstop = &unit($3);
    $stepsize = &unit($4);
  }
  if($stepstart<=0) {$stepstart=1e-9;}
  $n=$stepstart;
  $m=0;
  while($n<$stepstop) {
    if($n eq $stepstop) {last;}
    $steparray[$m]=$n;
    $n=$stepstart*(10**(1/$stepsize))**($m+1);
    $m++;
  }
  $steparray[$m]=$stepstop; # last element
  return ($stepparam,$m+1);
}
# param paramname [lin] start stop size
sub step_lin {
   my($n,$m,$stepparam,$stepstart,$stepstop,$stepsize);

   $deck[$i]=~s/lin//;
   if($deck[$i]=~s/param\s+(\S+)\s+(\S+)\s+(\S+)\s+(\S+)//i) {
     $stepparam = &unit($1);
     $stepstart = &unit($2);
     $stepstop = &unit($3);
     $stepsize = &unit($4);
   }
   $m=0;
   for($n=$stepstart;$n<$stepstop;$n+=$stepsize) {
     if($n eq $stepstop) {last;}
     $steparray[$m]=$n;
     $m++;
   }
   $steparray[$m]=$stepstop; # last element
   return ($stepparam,$m+1);
}
# param paramname list 1 2 3 4 5 .....
sub step_list {
   my($n,$m,$val,$stepparam);

   $deck[$i]=~s/param\s+(\S+)\s+\blist\b\s+(.*)//i;
   $stepparam=$1;
   @steparray=split(/ /,$2);
   $m=0;
   foreach $val (@steparray)  {
      $steparray[$m]=&unit($val); ##############################
      $m++;
   }
   return ($stepparam,$m);
}
sub read_controllines {
  my($contrl,$i,@kill);

  $contrl=0;
  for ($i=1;$i<@deck;$i++) {   # for the whole deck
    $_=$deck[$i];
    if (m/^\.control/i) {push @kill,$i;$contrl=1;next;}
    if (m/^\.endc/i ) {push @kill,$i;$contrl=0;next;}
    if ($contrl) {
       push @control,$_; # save controllines
       push @kill,$i;
    }
  }
  &zapdeck(@kill);
}
sub read_probelines {
    my ($i,$n);
    my ($temp,$found,$tmp,@kill);
    $n=-1;
    $found=0;
    for ($i=1;$i<@deck;$i++) {   # for the whole deck
       $_=$deck[$i];
       if ( m/^\.probe\s+(.*)/i ) {
           $n++;
           $vec[$n]="";
           $probelines=$n+1;
           $found=1;
           $temp = $1 ; # rest as String
           $vec[$n] = $temp;
           push @kill,$i; # prep. lines for deletion
       }
    }
    &zapdeck(@kill); # now delete lines
    if ($found==1 && !$step) { # if no parameterstepping = single run we can yet deal with plotlines
        push(@probe,".control");
        for($i=0;$i<$probelines;$i++) {
      	   $_=$vec[$i];
      	   if(m/\S+/) {push(@probe,"plot ".$vec[$i]);}
      	   else {push(@probe,"plot v(0)"); } # if only .probe
        }
        push(@probe,".endc");
    }
}
sub read_funcs {
    my($i,$m,$n,$found,$pm,$nr_pm,$parm,$ex);
    my(@pmvec);
    my(@kill);
    #============================================================================#
    #search, collect funcname, parametercount, subs parameter with x1,x2 in expr.#
    #============================================================================#
    $found=0;
    $memidx=$m=$fidx-1; # startidx of user defined .func lines
    $n=$pfidx-1; # startidx of user defined .pfunc lines
    for ($i=1;$i<@deck;$i++) {     # for the whole deck
       $_=$deck[$i];
       if ( m/^\.func/i ) { # .func
            $found=1;
            $m++;$n++; # synchronize .func with .pfunc
            m/\s+([^\(]+)\(([^\)]+)\)\s+(.*)/i; #  fname, parameter , expr
            # how many params in $2 ? neg(x)=((x)*(x)) -> $1=neg $2=x $3=((x)*(x))
            $funcname[$m]=$1;
            $parm=$2;
            $ex=$3;$ex=~s/\s//g; # delete blanks NEW 31.07.05
            $funcname[$m]=~s/\s//g; # delete blanks NEW NEW NEW 31.07.05
            $pfuncname[$n]=$funcname[$m]; # NEW NEW NEW NEW 31.07.05 synchronize pfunc with func
            $parm=~s/\s//g; # delete blanks
            @pmvec=split(/,/,$parm); # x
            $anz_pm[$m]=@pmvec; # 1
            $panz_pm[$n]=$anz_pm[$m]; # NEW NEW NEW NEW 25.12.05 synchronize pfunc with func
            $_=$ex; #expr ((x)*(x))
            $nr_pm=0;
            foreach $pm  (@pmvec) { # subs with xx1 , xx2 ...
               $nr_pm++;
               s/\b$pm\b/"__".$nr_pm/eg; # exact search (full name) on $pm (not part of name)
            }
            $expr[$m]=$_; # expr with $1,$2,$3 as paramvars
            $pexpr[$n]=$_; # expr with $1,$2,$3 as paramvars NEW NEW 31.07.05 for comp with pspice
            push @kill,$i; # prep. lines for deletion
            $memidx=$m; # NEW NEW NEW
       }
    }
    &zapdeck(@kill); # now delete line
}
sub read_pfuncs {
    my($i,$m,$found,$pm,$nr_pm,$parm,$ex);
    my(@pmvec);
    my(@kill);
    #============================================================================#
    #search, collect funcname, parametercount, subs parameter with x1,x2 in expr.#
    #============================================================================#
    $found=0;$m=$memidx2=$pfidx+$memidx-$fidx; #$pfidx-1; # startidx of user defined .pfunc lines NEW NEW NEW
    for ($i=1;$i<@deck;$i++) {   # for the whole deck
       $_=$deck[$i];
       if ( m/^\.pfunc/i ) { # .pfunc
            $found=1;$m++;
            m/\s+([^\(]+)\(([^\)]+)\)\s+(.*)/i; #  fname, parameter , expr
            $pfuncname[$m]=$1;
            # how many params in $2 ? neg(x)=((x)*(x)) -> $1=neg $2=x $3=((x)*(x))
            $parm=$2;
            $ex=$3;$ex=~s/\s//g; # delete blanks NEW 31.07.05
            $pfuncname[$m]=~s/\s//g; # delete blanks
            $parm=~s/\s//g;
            @pmvec=split(/,/,$parm); # x
            $panz_pm[$m]=@pmvec; # 1
            $_=$ex; #expr ((x)*(x))
            $nr_pm=0;
            foreach $pm  (@pmvec) { # subs with x1 , x2 ...
               $nr_pm++;
               s/\b$pm\b/"__".$nr_pm/eg; # exact search (full name) on $pm (not part of name)
            }
            $pexpr[$m]=$_; # expr with $1,$2,$3 as paramvars
            push @kill,$i; # prep. lines for deletion
            $memidx2=$m; # NEW NEW NEW
       }
    }
    &zapdeck(@kill); # now delete line
}
#===========================================================================#
#substitute all (p)func on rhs of .(p)funclines (func is defined by func(s))#
#===========================================================================#
sub eval_funcs {
       my($i,$anz,$fnr,$pm,$parm,$subexpr,$fname,$par_on,$par_off,$rest,$fexpr);
       my($nr_pm,$tmp,$se,$sex,$n,$search_ahead,$text);
       local(@pm_neu);

       $fnr=0;
       foreach $fname  (@funcname) {  # for all .func fname definitions
           if ($fnr == 0) {goto marke; }
           $_=$expr[$fnr];
           for ($i=0;$i<$fnr;$i++) {
               $fexpr="";$_=$expr[$fnr];
               # OLD while ( m/$funcname[$i]/ig ) # isol. funcname( , , ) and store in $fexpr.
               while ( m/\b$funcname[$i]\b/ig ) { # isol. funcname( , , ) and store in $fexpr.
                  $fexpr=$fexpr.$funcname[$i];
                  $par_off=0;$par_on=0;$rest="";$search_ahead=1;
                  while ($search_ahead) {
                     if ( m/([^\)]*)/ig) { #  store everything till paranthesis closed in $1
                         $rest=$rest.$1;
                         $par_off++;
                     }
                     $text=$1;
                     $par_on += $text =~ tr/\(//;
                     if ( ($par_on-$par_off)>= 1 ) {
                          m/\)/ig;
                          $rest = $rest.")"; # add )
                     }
                     else {$search_ahead=0;}
                  }
                  m/\)/ig; # read last ) - prepare for ( possible ) next loop
                  $fexpr=$fexpr.$rest.")";
                  $_ = $fexpr;
                  m/\s*([^\(]+)\((.*)/i; # search for funcname = $1 rest = $2
                  $parm=$2;
                  $parm=~s/\s//g;  # eats all spaces
                  $anz=@pm_neu = split(/,/,$parm); # store new parameter(expressions) in array
                  chop($pm_neu[$anz-1]); # delete last ) in last parameter
                  ##########################################################################################################
                  if($anz!=$anz_pm[$i]) { # special treatment if functions are nested ( argument of function is a function )
                                          # because of additional "," commas in expression !
                          @pm_neu=&resolve_nested_funcs($i,$anz);
                  }
                  if($anz_pm[$i]!=@pm_neu) { print"Error: function: $fname expr:($fexpr) in b-line $i : nr. of open/closed paranthesis or nr. of parameters not ok!"; exit(1);}
                  ##########################################################################################################
                  $subexpr=$expr[$i];
                  $n=0;
                  foreach $pm (@pm_neu) {
                       $n++;$se="__".$n;$sex=$se.$n;
                       $subexpr =~ s/\b$se\b/$sex/g; # global one or more times
                  }
                  $n=0;
                  foreach $pm (@pm_neu) {
                       $n++;$se="__".$n.$n;
                       $subexpr =~ s/\b$se\b/$pm/g; # global one or more times
# for more security $subexpr could be also with additional paranthesis "$subexpr=~s/\b$se\b/\($pm\)/g;"
                  }
                  # write back subs expr in $expr
                  $expr[$fnr] =~ s/\s*//g;  # eats all spaces before
                  $fexpr =~ s/\s*//g;  # eats all spaces before
                  $fexpr=quotemeta($fexpr); # all special characters get a backslash in front
                  $expr[$fnr] =~ s/$fexpr/$subexpr/g; # new /g option
                  $fexpr=""; # clean up for new loop;
                  $_=$expr[$fnr];
               }
           }
       marke: $fnr++;
       }
}
sub eval_pfuncs {
       my($i,$anz,$fnr,$pm,$parm,$par_off,$par_on,$rest,$subexpr,$fname,$fexpr);
       my($nr_pm,$tmp,$se,$sex,$n,$search_ahead,$text);
       local(@pm_neu);

       $fnr=0;
       foreach $fname  (@pfuncname) {  # for all .func fname definitions
           if ($fnr == 0) {goto marke; }
           $_=$pexpr[$fnr];
           for ($i=0;$i<$fnr;$i++) {
               $fexpr="";$_=$pexpr[$fnr];
               while ( m/\b$pfuncname[$i]\b/ig ) { # isol. funcname( , , ) and store in $fexpr.
                  $fexpr=$fexpr.$pfuncname[$i];
                  $par_off=0;$par_on=0;$rest="";$search_ahead=1;
                  while ($search_ahead) {
                     if ( m/([^\)]*)/ig)  { #  store everything till paranthesis closed in $1
                         $rest=$rest.$1;
                         $par_off++;
                     }
                     $text=$1;
                     $par_on += $text =~ tr/\(//;
                     if ( ($par_on-$par_off)>= 1 ) {
                          m/\)/ig;
                          $rest = $rest.")"; # add )
                     }
                     else {$search_ahead=0;}
                  }
                  m/\)/ig; # read last ) - prepare for ( possible ) next loop
                  $fexpr=$fexpr.$rest.")";
                  $_ = $fexpr;
                  m/\s*([^\(]+)\((.*)/i; # search for funcname = $1 rest = $2
                  $parm=$2;
                  $parm=~s/\s//g;  # eats all spaces
                  $anz=@pm_neu = split(/,/,$parm); # store new parameter(expressions) in array
                  chop($pm_neu[$anz-1]); # delete last ) in last parameter
                  ##########################################################################################################
                  if($anz!=$panz_pm[$i]) { # special treatment if functions are nested ( argument of function is a function )
                                          # because of additional "," commas in expression !
                          @pm_neu=&resolve_nested_funcs($i,$anz);
                  }
                  if($panz_pm[$i]!=@pm_neu) { print"Error: function: $fname expr:($fexpr) in b-line $i : nr. of open/closed paranthesis or nr. of parameters not ok!"; exit(1);}
                  #########################################################################################################
                  $subexpr=$pexpr[$i];
                  $n=0;
                  foreach $pm (@pm_neu) {
                       $n++;$se="__".$n;$sex=$se.$n; # make parameter unique xx1 xx2 -> xx11 xx22 before substitution
                       $subexpr =~ s/\b$se\b/$sex/g; # global one or more times
                  }
                  $n=0;
                  foreach $pm (@pm_neu) {
                       $n++;$se="__".$n.$n; # now substitute unique parameter xx11 xx22 ... with xx1 xx2 ...
                       $subexpr =~ s/\b$se\b/$pm/g; # global one or more times
# for more security $subexpr could be also with additional paranthesis "$subexpr=~s/\b$se\b/\($pm\)/g;"
                  }
                  # write back subs expr in $expr
                  $pexpr[$fnr] =~ s/\s//g;  # eats all spaces before ?
                  $fexpr =~ s/\s//g;  # eats all spaces before ?
                  $fexpr=quotemeta($fexpr); # all special characters get a backslah in front
                  $pexpr[$fnr] =~ s/$fexpr/$subexpr/g;
                  $fexpr=""; # clean up for new loop;
                  $_=$pexpr[$fnr];
               }
           }
       marke: $fnr++;
       }
}
#================================================================================================#
# substitute all pfunc expressions on rhs of .paramlines or in expressions on devicelines { xxx } #
#================================================================================================#
#===================================================#
# substitute all func expressions on b-devicelines  #
#===================================================#
sub expand_funclines { # only for b-sources ( b-source syntax )
     my($i,$n,$m,$j,$anz,$par_on,$par_off,$pm,$parm,$head,$tail,$fexpr);
     my($parcnt,$pcnt,$rest,$subexpr,$temp,$fname,$text,$sexp,$rexp);
     local($search_ahead,$se,$sex,@pm_neu);

     for ($i=1;$i<@deck;$i++) {   # for the whole deck
       $_=$deck[$i];
       if ( m/(^b\S+[^\=]*\=)(.*)/i ) { # search for bxxx bla bla v= or i= expr $2 = expr
           $head=$1; # everything till including =
           $tail=$2; # expr
           $m=-1;
           foreach $fname (@funcname) {
              $m++; $_=$tail;
              while(m/(\b$fname\b\s*\()/ig) { # while(m/$fname/ig)
                  $fexpr=$fexpr.$funcname[$m];
                  $par_off=0;$par_on=1;$rest="(";$search_ahead=1;
                  while ($search_ahead) {
                     if ( m/([^\)]*)/ig) { #  store everything till paranthesis closed in $1
                         $rest=$rest.$1;
                         $par_off++;
                     }
                     $text=$1;
                     $par_on += $text =~ tr/\(//;
                     if ( ($par_on-$par_off)>= 1 ) {
                          m/\)/ig;
                          $rest = $rest.")"; # add )
                     }
                     else {$search_ahead=0;}
                  }
                  m/\)/ig; # read last ) - prepare for ( possible ) next loop
                  $fexpr=$fexpr.$rest.")";
                  $_ = $fexpr;
                  m/\s*([^\(]+)\((.*)/i; # search for funcname = $1 rest = $2
                  @pm_neu=();
                  $parm=$2;
                  $parm=~s/\s//g;  # eats all spaces
                  # v(1,2) -> v(1:2) translation for correct parameter count
                  $_=$parm;
                  while( m/\bv\s*\(([^\)]*)\)/g) { # new to handle differential voltages (don't see v(1,2) as a functions)
                  	$sexp=$rexp=$1;
                  	$rexp=~s/,/:/;
                  	$parm=~s/$sexp/$rexp/;
                  }
                  $anz=@pm_neu = split(/,/,$parm); # store new parameter(expressions) in array
                  chop($pm_neu[$anz-1]); # delete last ) in last parameter
                  ##########################################################################################################
                  if($anz!=$anz_pm[$m]) { # special treatment if functions are nested ( argument of function is a function )
                                          # because of additional "," commas in expression !
                          @pm_neu=&resolve_nested_funcs($m,$anz);
                  }
                  if($anz_pm[$m]!=@pm_neu) { print"Error: function: $fname expr:($fexpr) in b-line $i : nr. of open/closed paranthesis or nr. of parameters not ok!"; exit(1);}
                  #########################################################################################################
                  $subexpr=$expr[$m];
                  $n=0;
                  foreach $pm (@pm_neu) {
                       $pm=~s/:/,/g; # v(1:2) -> v(1,2) re-translation ++
                       $n++;$se="__".$n;$sex=$se.$n; # make parameter unique xx1 xx2 -> xx11 xx22 before substitution
                       $subexpr =~ s/\b$se\b/$sex/g; # global one or more times
                  }
                  $n=0;
                  foreach $pm (@pm_neu) {
                       $n++;$se="__".$n.$n; # now substitute unique parameter xx11 xx22 ... with xx1 xx2 ...
                       $subexpr =~ s/\b$se\b/$pm/g; # global one or more times
# for more security $subexpr could be also with additional paranthesis "$subexpr=~s/\b$se\b/\($pm\)/g;"
                  }
                  $tail =~ s/\s*//g;  # eats all spaces before
                  $fexpr =~ s/\s*//g;  # eats all spaces before
                  $fexpr=quotemeta($fexpr); # all special characters get a backslah in front
                  $tail =~ s/$fexpr/$subexpr/g;
                  $fexpr=""; # clean up for new loop;
                  $_=$tail;
              }
           }
       $deck[$i]=$head.$tail;  # writeback
       }
    }
}

sub expand_pfunclines { # for all {} expressions ( perl syntax )
    my($i,$n,$m,$j,$anz,$pm,$parm,$head,$tail,$fexpr,$parcnt,$pcnt,$rest,$subexpr,$found,$temp,$fname,$text);
    local($search_ahead,$se,$sex,@pm_neu);

     for ($i=1;$i<@deck;$i++) {   # for the whole deck
        $_=$deck[$i];$head=();$found=0;   #
        while ( /([^\{]*)\{([^\}]*)\}(.*)/ ) { # search for {} expressions
            $found=1;
            $head=$head.$1; $tail=$3;
            $temp = $2; # actual expression to deal with ( e.g. .param b = {2*neg(a)*neg(a)*pos(a)} )
            $temp =~ s/\*\s+\*/\*\*/g;
            $m=-1;
            foreach $fname (@pfuncname) {
              $m++; $_=$temp;
              while(m/(\b$fname\b\s*\()/ig) {
                  $fexpr=$fexpr.$pfuncname[$m];
                  $par_off=0;$par_on=1;$rest="(";$search_ahead=1;
                  while ($search_ahead) {
                     if ( m/([^\)]*)/ig) { #  store everything till paranthesis closed in $1
                         $rest=$rest.$1;
                         $par_off++;
                     }
                     $text=$1;
                     $par_on += $text =~ tr/\(//;
                     if ( ($par_on-$par_off)>= 1 ) {
                          m/\)/ig;
                          $rest = $rest.")"; # add )
                     }
                     else {$search_ahead=0;}
                  }
                  m/\)/ig; # read last ) - prepare for ( possible ) next loop
                  $fexpr=$fexpr.$rest.")";
                  $_ = $fexpr;
                  m/\s*([^\(]+)\((.*)/i; # search for funcname = $1 rest = $2
                  @pm_neu=();
                  $parm=$2;
                  $parm=~s/\s//g;  # eats all spaces
                  $anz=@pm_neu = split(/,/,$parm); # store new parameter(expressions) in array
                  chop($pm_neu[$anz-1]); # delete last ) in last parameter
                  ##########################################################################################################
                  if($anz!=$panz_pm[$m]) { # special treatment if functions are nested ( argument of function is a function )
                                          # because of additional "," commas in expression !
                          @pm_neu=&resolve_nested_funcs($m,$anz);
                  }
                  if($panz_pm[$m]!=@pm_neu) { print"Error: function: $fname expr:($fexpr) in b-line $i : nr. of open/closed paranthesis or nr. of parameters not ok!"; exit(1);}
                  #########################################################################################################
                  $subexpr=$pexpr[$m];
                  $n=0;
                  foreach $pm (@pm_neu) {
                       $n++;$se="__".$n;$sex=$se.$n; # make parameter unique xx1 xx2 -> xx11 xx22 before substitution
                       $subexpr =~ s/\b$se\b/$sex/g; # global one or more times
                  }
                  $n=0;
                  foreach $pm (@pm_neu) {
                       $n++;$se="__".$n.$n; # now substitute unique parameter xx11 xx22 ... with xx1 xx2 ...
                       $subexpr =~ s/\b$se\b/$pm/g; # global one or more times
                  }
                  # write back subs expr in $expr
                  $temp =~ s/\s*//g;  # eats all spaces before
                  $fexpr =~ s/\s*//g;  # eats all spaces before
                  $fexpr=quotemeta($fexpr); # all special characters get a backslash in front
                  $temp =~ s/$fexpr/$subexpr/g; # new /g option
                  $fexpr=""; # clean up for new loop;
                  $_=$temp;  # perhaps another param in line ?
              }
           }
       $head=$head."{".$temp."}"; # append
       $_=$tail;
       }
    if($found) { # if {} expression found and therefore -> $head evaluated
    $deck[$i]=$head.$tail;  # writeback
    }
  }
}

sub resolve_nested_funcs {
   my($fnr,$cnt)=@_;
   my($anz,$mm,$k,@tmp,$par_on,$par_off,$pm_ok);

   # ( local @pmneu )

   @tmp=();$mm=0;
   $pm_ok=$pm_neu[0];
   for($k=0;$k<($cnt-1);$k++) {
       $_=$pm_ok;
       $par_on = tr/\(//; # count of open paranthesis
       $par_off = tr/\)//; # count of closed paranthesis
       if($par_on!=$par_off) { # nested ! -> additional paranthesis -> because of function as argument of function
           $pm_ok=$pm_ok.",".$pm_neu[$k+1];
       }
       else { # now the parameter is perfect
          $tmp[$mm++]=$pm_ok;
          $pm_ok=$pm_neu[$k+1];
       }
   }
   $tmp[$mm]=$pm_ok; # manage last element
   return(@tmp);
}

sub check {
   my($i,$par_on,$par_off);

    foreach $key  (keys %param) {   # for all parameters
       $_=$param{$key};
       $par_on = tr/\(//; # count of open paranthesis
       $par_off = tr/\)//; # count of closed paranthesis
       if(not($par_on eq $par_off)) {
            print "Nr of opened and closed paranthesis differs -> please check param $key = $val";
            &hint;
           exit;
       }
       $par_on = tr/\{//; # count of open paranthesis
       $par_off = tr/\}//; # count of closed paranthesis
       if(not($par_on eq $par_off)) {
            print "Nr of opened and closed paranthesis differs -> please check param $key = $val";
            &hint;
           exit;
       }
       if(m/\{[^\}]*?\{/g) { # not greedy
           print "Nested curly braces found -> please check param $key = $val";
           &hint;
           exit;
       }
       if(m/\{[^\}]*?\{/g) { # not greedy
           print "Nested curly braces found -> please check param $key = $val";
           &hint;
           exit;
       }
    }
    for ($i=0;$i<@expr;$i++) {    # for all functions
       $_=$expr[$i];
       # @funcname @expr
       # @pfuncname @pexpr
       $par_on = tr/\(//; # count of open paranthesis
       $par_off = tr/\)//; # count of closed paranthesis
       if(not($par_on eq $par_off)) {
            print "Nr of opened and closed paranthesis differs -> please check func nr: $i ";
            print "\n\funcname: $funcname[$i] expr: $expr[$i]\n";
            &hint;
           exit;
       }
       $par_on = tr/\{//; # count of open paranthesis
       $par_off = tr/\}//; # count of closed paranthesis
       if(not($par_on eq $par_off)) {
            print "Nr of opened and closed paranthesis differs -> please check func nr: $i ";
            print "\n\funcname: $funcname[$i] expr: $expr[$i]\n";
            &hint;
           exit;
       }
       if(m/\{[^\}]*?\{/g) { # not greedy
           print "Nested curly braces found -> please check func nr: $i ";
           print "\n\funcname: $funcname[$i] expr: $expr[$i]\n";
           &hint;
           exit;
       }
       if(m/\{[^\}]*?\{/g) { # not greedy
           print "Nested curly braces found -> please check func nr: $i ";
           print "\n\funcname: $funcname[$i] expr: $expr[$i]\n";
           &hint;
           exit;
       }
    }
    for ($i=0;$i<@pexpr;$i++) {    # for all pfunctions
       $_=$pexpr[$i];
       $par_on = tr/\(//; # count of open paranthesis
       $par_off = tr/\)//; # count of closed paranthesis
       if(not($par_on eq $par_off)) {
            print "Nr of opened and closed paranthesis differs -> please check pfunc nr: $i ";
            print "\n\funcname: $pfuncname[$i] expr: $pexpr[$i]\n";
            &hint;
           exit;
       }
       $par_on = tr/\{//; # count of open paranthesis
       $par_off = tr/\}//; # count of closed paranthesis
       if(not($par_on eq $par_off)) {
            print "Nr of opened and closed paranthesis differs -> please check pfunc nr: $i ";
            print "\n\funcname: $pfuncname[$i] expr: $pexpr[$i]\n";
            &hint;
           exit;
       }
       if(m/\{[^\}]*?\{/g) { # not greedy
            print "Nested curly braces found -> please check pfunc nr: $i ";
            print "\n\funcname: $pfuncname[$i] expr: $pexpr[$i]\n";
            &hint;
           exit;
       }
       if(m/\{[^\}]*?\{/g) { # not greedy
            print "Nested curly braces found -> please check pfunc nr: $i ";
            print "\n\funcname: $pfuncname[$i] expr: $pexpr[$i]\n";
            &hint;
           exit;
       }
    }
    for ($i=1;$i<@deck;$i++) {   # for the whole deck
       $_=$deck[$i];
       $par_on = tr/\(//; # count of open paranthesis
       $par_off = tr/\)//; # count of closed paranthesis
       if(not($par_on eq $par_off)) {
            print "Nr of opened and closed paranthesis differs -> please check about line $i in sub.tmp";
            print "\n\n.... $deck[$i-1]\n";
            print "error: -> $deck[$i]\n";
            print ".... $deck[$i+1]\n";
            &hint;
           exit;
       }
       $par_on = tr/\{//; # count of open paranthesis
       $par_off = tr/\}//; # count of closed paranthesis
       if(not($par_on eq $par_off)) {
            print "Nr of opened and closed paranthesis differs -> please check about line $i in sub.tmp";
            print "\n\n.... $deck[$i-1]\n";
            print "error: -> $deck[$i]\n";
            print ".... $deck[$i+1]\n";
            &hint;
           exit;
       }
       if(m/^[efgh]/i && m/value/i) {next;} # nested curly braces are managed by value2bdevice itself
       if(m/\{[^\}]*?\{/g) { # not greedy
            print "Nested curly braces found -> please check about line $i in sub.tmp";
            print "\n\n.... $deck[$i-1]\n";
            print "error: -> $deck[$i]\n";
            print ".... $deck[$i+1]\n";
            &hint;
           exit;
       }
       if(m/\}[^\{]*?\}/g) { # not greedy
            print "Nested curly braces found -> please check about line $i in sub.tmp";
            print "\n\n.... $deck[$i-1]\n";
            print "error: -> $deck[$i]\n";
            print ".... $deck[$i+1]\n";
            &hint;
           exit;
       }
    }
}
sub value2bdevice {   # new search for pspice efgh value lines and convert to b v= or b i=
    my ($i,$templine);

    for ($i=1;$i<@deck;$i++) {    # for the whole deck
       $_=$deck[$i];
       if(m/^([efgh])/i && m/value/i) { # pspice value line detected
          s/tripdv(.*)//; # to deal with ltspice tripdt , tripdv
          s/tripdt(.*)//;
          s/value\s*\=\s*\{/v=/i; # subs "value = {" with "v="
          s/value\s*\{\s*/v=/i; # NEW subs "value { " with "v="
          $deck[$i]=$_; # write back
          s/(v\=.*)\}/$1/; # search for rhs expression without (last closed) paranthesis (greedy)
          $templine=$1;
          $templine=~tr/\{\}/\(\)/; # sometimes pspice users use 2nd order {} inside {}'s
          $templine=~s/\s*//g; # NEW delete all blanks in rhs expression
          $templine=~s/(\d)V/$1/ig; # NEW 10v -> 10
          $templine =~ s/([\+\-\*\/\&\|\=\^])\+/$1/; # sometimes pspice adds a "surplus +" at the end of a continuation line -> delete it
          $_=$deck[$i];
          s/v=.*/$templine/;
          if ( m/^[GF]/i) {  # G or F at first  -> v= -> i=
             s/v=/i=/; # currrentsources
          }
          s/^([GFEH])/b$1/i; # subs G,F,E or. H with b(EFGH)
          $deck[$i]=$_;   #."+v(0)"; #DONE IN &expand_parameters
       }
    }
}
sub model_r {   # search for r1 1 0 10 tc=0,0 and delete tc=0,0 add .model rmodel R  modelline
    my ($i,$tc,$tc1,$tc2,$rsh,$rmodname);
    for ($i=1;$i<@deck;$i++) {    # for the whole deck
       $_=$deck[$i];
       if(m/^r(\w+)/i) { # r1
         $rmodname="mod_r".$1; #s/tc.*$/tc=0,0/; # r .... tc=0,0 line detected
         if(s/tc\s*=\s*(.*)$//) { #  $1 = tc=tc1,tc2 or tc=(tc1,tc2) or tc=tc1 or tc=(tc1)
            $deck[$i]=$_; # r1 1 0 rval
            $tc=$_=$1;   # tc=tc1,tc2 or tc=tc1
            s/[\)\(]//g;  # deletes ( ) if present
            if(m/(\S+)\s*\,\s*(\S+)/) { # first form tc=tc1,tc2
                $tc1=$1;
                $tc2=$2;
                $deck[$i]=~s/(\S+)\s*$/$1 $rmodname/; # change r-line -> cut rvalue and add modelname
                # rvalue = $1
                #insert .model-line and increase index i
                splice(@deck,$i+1,0,".model $rmodname R ( tc1=$tc1 tc2=$tc2 tnom=$tnom )");
                $i++;
            }
            else { # 2nd form tc=tc1
                $deck[$i]=~s/(\S+)\s*$/$rmodname/; # change r-line -> cut rvalue and add modelname
                # rvalue = $1
                #insert .model-line and increase index i
                splice(@deck,$i+1,0,".model $rmodname R ( tc1=$tc tnom=$tnom )");
                $i++;
            }
         }
       }
       $_=$deck[$i];
       if(m/^.model\s+(\w+)\s+(\w+)/) { # search for .model rmodel RES -> change to .model rmodel R
    	  $_=$2;
    	  if(m/RES/i) { # is it a pspice - resistormodel
    	     	$deck[$i]=~s/RES/R/i; # change modelname to R
    	  }

       }
    }
}
sub model_r_spice3 {   # search for r1 1 0 rval tc=0,0 and convert to  r1 1 0 rvaltc1tc2 = rval + rval*tc1 + rval*tc2

    my ($i,$tc,$tc1,$tc2,$rsh,$rvaltc1tc2);

    for ($i=1;$i<@deck;$i++){   # for the whole deck
       $_=$deck[$i];
       if(m/^r/i) { # e.g r1 1 0 rval tc=tc1,tc2
         if(s/tc\s*=\s*(.*)$//) { #  $1 = tc=tc1,tc2 or tc=(tc1,tc2) or tc=tc1 or tc=(tc1)
            $deck[$i]=$_; # now r1 1 0 rvalue  (tc=val,val cutted)
            $tc=$_=$1;   # tc=tc1,tc2 or tc=tc1
            s/[\)\(]//g;  # deletes ( ) if present
            if(m/(\S+)\s*\,\s*(\S+)/) { # first form tc=tc1,tc2
                $tc1=$1;
                $tc2=$2;
            }
            else { # 2nd form tc=tc1
                $tc1=$tc;
                $tc2=0;
            }
            $deck[$i]=~s/(\S+)\s*$//; # cut rvalue
            $rsh=&unit($1); # rvalue
            $rvaltc1tc2 = "{$rsh*(1+($tc1)*(temp-27)+($tc2)*(temp-27)*(temp-27))}";
            $deck[$i]=$deck[$i]." ".$rvaltc1tc2; #  r1 1 0 { rvalue*(1+tc1*(temp-27)+tc2*(temp-27)*(temp-27)) }
                                                 # rvalue and tc1 and tc2 are constants , temp = parameter
         }
       }
       if(m/^.model\s+(\w+)\s+(\w+)/) { # search for .model rmodel RES -> change to .model rmodel R
    	  $_=$2;
    	  if(m/RES/i) { # is it a pspice - resistormodel
    	     	$deck[$i]=~s/RES/R/i; # change modelname to R
    	  }
       }
    }
}
sub model_switch {
    my ($i,$k,$cnt);
    my (%swmodel,$modelnm,$kindofmodel,$vctrllim,$vswitch,$found);
    my ($xon,$xoff,$von,$voff,$ion,$ioff,$ron,$roff,$par); # model parameters
    my ($node1,$node2,$ctrlnode1,$ctrlnode2,$ctrlsrc,$xtmp);
    my ($mline,$lline,$hline);  # converted modellines (PSPICE s-device + .modelline) in two spice3 b-lines
    my ($lm,$lr,$um,$ud,$c2,$c3); # pspice switcher model
    my $optline=".options trtol=1 chgtol=1e-16"; # add this for better convergence

    %swmodel=();
    $von=1;$voff=0.0;$ion=0.001;$ioff=0.0; # default for pspice !
    $xon=1;$xoff=0;$ron=1;$roff=1e6;
    $k=0;$found=0;

    for ($i=1;$i<@deck;$i++) {   # for the whole deck
       $_=$deck[$i];
       $von=$voff=0;
       if(s/^.model\s+(\w+)\s+(\w+)//i) { # search for .model modelname ISWITCH/VSWITCH and delete it
      	  $modelnm=$1;
      	  $kindofmodel=$2;
      	  if($kindofmodel eq 'vswitch' || $kindofmodel eq 'iswitch' ) {
      	     # now only present -> (von=xx voff=xx ron=xx roff=xx)
      	     s/[\=\)\(]/ /g;
      	     $swmodel{$modelnm}=$kindofmodel." ".$_;
      	     if($found==1) {
      		splice(@deck,$i,1); # just delete line
      	        $i--;
      	     }
      	     else { # first time .model VSWITCH || ISWITCH -> add optline
      		splice(@deck,$i,1,$optline); # $optline instead of .modelline ($i--)
      		$found=1;
      	     }
      	  }
       }
    }
    $cnt=0;
    for ($i=1;$i<@deck;$i++) {    # for the whole deck
       $_=$deck[$i];
       if(/^([sw])/) {
       	  $cnt++;
       	  if($1 eq 's') {
       	      /^s(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)/; # search for -> s1 out1 out2 ctrl1 ctrl2 modelname
       	      $node1=$2;
              $node2=$3;
              $ctrlnode1=$4;
              $ctrlnode2=$5;
              $modelnm=$6;
       	  }
       	  else { # must be w
       	      /^w(\w+)\s+(\w+)\s+(\w+)\s+(\w+)\s+(\w+)/; # search for -> w1 out1 out2 vname  modelname
       	      $node1=$2;
              $node2=$3;
              $ctrlsrc=$4;
              $modelnm=$5;
              $ctrlnode1="0";
              $ctrlnode2="visw$cnt";
          }
          #extract parameters for mline
          if(exists $swmodel{$modelnm}) {
              @mpar = split(' ',$swmodel{$modelnm}) if(exists $swmodel{$modelnm});
          }
          else {
              print("\nError: S-deviceline line: $i with undefined model ! \n");
              exit(1);
          }
          if(shift(@mpar) eq 'vswitch') {$vswitch=1;$xon=$von;$xoff=$voff;} # default values for VSWITCH
          else {$vswitch=0;$xon=$ion;$xoff=$ioff;} # default values for ISWITCH
          while($par=shift(@mpar)) {
             if($vswitch) {
            	if($par eq 'von') {$xon=$von=&unit(shift(@mpar));next;}
            	if($par eq 'voff') {$xoff=$voff=&unit(shift(@mpar));next;}
             }
             else { # iswitch
             	if($par eq 'ion') { $xon=$ion=&unit(shift(@mpar));next;}
            	if($par eq 'ioff') {$xoff=$ioff=&unit(shift(@mpar));next;}
             }
             if($par eq 'ron') {$ron=&unit(shift(@mpar));next;}
             if($par eq 'roff') {$roff=&unit(shift(@mpar));next;}
          }
          if($xon<$xoff) {
             $ron=-$ron;
             $roff=-$roff;
          }
          ################################
          $lm=log(($ron*$roff)**0.5);
          $lr=log($ron/$roff);
          ################################
          $um=($xon+$xoff)/2;
          $ud=($xon-$xoff);
          $c2=3*$lr/(2*$ud);
          $c3=-2*$lr/($ud**3);
          $mline="bsw$cnt $node2 $node1 i=";
          if($xon<$xoff){$xtmp=$xon;$xon=$xoff;$xoff=$xtmp;}
          # because of my limit function definition: LIMIT(x,lowerlim,uperlim)
          # in ltspice the definition is LIMIT(x,MIN(lowerlim,uperlim),MAX(lowerlim,uperlim))
          # where LIMIT means my limit function definition
          $lline="bswlim$cnt vlim$cnt 0 v=limit((v($ctrlnode1)-v($ctrlnode2)),$xoff,$xon)"; $mline=$mline."v($node2,$node1)/(e^($lm+$c2*(v(vlim$cnt)-$um)+$c3*(v(vlim$cnt)-$um)^3))";
          #$lline="bswlim$cnt vlim$cnt 0 v=limit((v($ctrlnode1)-v($ctrlnode2)),$xoff,$xon)"; $mline=$mline."v($node2,$node1)/(exp($lm+$c2*(v(vlim$cnt)-$um)+$c3*(v(vlim$cnt)-$um)^3))";
          if ($vswitch) { # sline -vswitch
             splice(@deck,$i,1,$mline,$lline);$i++;
          }
          else { # wline - iswitch
             $hline="hisw$cnt visw$cnt 0 $ctrlsrc 1";
             splice(@deck,$i,1,$hline,$mline,$lline);$i=$i+2;
          }
       }
    }
}
# only for b-lines = funclines expansion
#  e1 1 0 value={idt(v(1))}  was converted to b1 1 0 v=idt(v(1)) and now processed to get a spice3 convenient expression
sub b_device_sdt_idt {
    my($bline,$lline,$rline,$fexpr,$replaceexpr,$cnt,$bname,$node1,$node2);
    my($fname,@funcname);
    my($head,$tail,$rest,$search_ahead,$par_off,$par_on,$text,$m,$i);

    $cnt=0;
    $m=0;
    $funcname[0]="idt";
    $funcname[1]="ddt";

    for ($i=1;$i<@deck;$i++) {   # for the whole deck
       $_=$deck[$i];
       if (m/[sid]dt\s*\(/i && m/^b/i )  {s/sdt/idt/g;} # this is a function "s[i]dt("
       else {next;}
       if(m/(^b\S+[^\=]*\=)(.*)/i ) { # $1 = "b1  1  0   v/i="   $2=rest of line
           $head=$1; # everything till =
           $tail=$2; # expr
           $m=-1; # indexcounter for  @funcname
	   foreach $fname (@funcname) {
  	      $m++;$_=$tail;
  	      while(m/(\b$fname\b\s*\()/ig) { #   one or more times fname present
                 $fexpr=$fexpr.$funcname[$m];
  		 $par_off=0;$par_on=1;$rest="(";$search_ahead=1;
  		 while ($search_ahead){
    		    if ( m/([^\)]*)/ig) { #  store everything till paranthesis closed in $1
    		       $rest=$rest.$1;
    		       $par_off++;
    		    }
    		    $text=$1;
    		    $par_on += $text =~ tr/\(//;
    		    if ( ($par_on-$par_off)>= 1 ) {
    		       m/\)/ig;
    		       $rest = $rest.")"; # add )
    		    }
    		    else {$search_ahead=0;}
  		 }
  		 m/\)/ig; # read last ) - prepare for ( possible ) next loop
  		 $fexpr=$fexpr.$rest.")";
  		 &idt_ddt_addlines($fname,$fexpr,$cnt,$i); # add lines for fname found in line
                 $tail =~ s/\s*//g;  # eats all spaces before
                 $fexpr =~ s/\s*//g;  # eats all spaces before
  		 $fexpr=quotemeta($fexpr);
  		 if($fname eq 'idt') {
                    $replaceexpr="v(vidt$cnt)";
  		 }
  		 else { # ddt
  		    $replaceexpr="v(vddt$cnt)";
  		  }
  		  $tail =~ s/$fexpr/$replaceexpr/;
  		  $fexpr=""; # clean up for new loop;
  		  $_=$tail; # starting again from begin of line
                  $cnt++;
  	      }
          }
	  $deck[$i]=$head.$tail; # writeback
        }
    }
}
sub idt_ddt_addlines {
  ($fname,$fexpr,$cnt,$i)=@_;

  my($name,$lline,$bline,$rline);

  if($fname eq 'idt') {  # test if nested   (sdt#..{ddt#.. �}.. �)   (sdt()....sdt) should be ok!
     $fexpr=~s/idt\(//;
     $fexpr=~s/\)$//;
     $name="idt$cnt";   # prevent the expression to go to long-> if nested sdt(sdt(sdt())) !!!
     $lline="c$name v$name 0 1";            # this is integrated
     $bline ="b$name 0 v$name i=$fexpr";  # this is to integrate
     $rline="r$name 0 v$name 1e6";  # for dc,operating point
     splice(@deck,$i+1,0,$lline,$bline,$rline); # only insert after actual line $i -> 3rd param = 0
  }
  else { # ddt
     $fexpr=~s/ddt\(//;
     $fexpr=~s/\)$//;
     $name="ddt$cnt"; # prevent the expression to go to long  if nested sdt(sdt(sdt())) !!!
     $lline="l$name v$name 0 1";          # this is differentiated
     $bline="b$name 0 v$name i=$fexpr";  # this to differentiate
     $rline="r$name 0 v$name 1e6";  # for dc,operating point
     splice(@deck,$i+1,0,$lline,$bline,$rline); # only insert after actual line $i -> 3rd param = 0
     # if 2nd param is $i -> actual line moves 4 lines down = appended to the inserted lines
     # if 2nd param is $i+1 -> actual line don't move
   }
}
sub r_expressions {
    my($i,$rexpr,$rname,$node1,$node2,$bline);

    for ($i=1;$i<@deck;$i++) {    # for the whole deck
        $_=$deck[$i];
        if(m/^r/i && m/value\s*=\s*\{(.*?)\}/i) { # r and value
           $rexpr=$1; # {rexpr}
           s/^(\S+)\s+(\S+)\s+(\S+)//;
      	   $rname=$1;
      	   $node1=$2;
           $node2=$3;
      	   # now convert to equivalent b-source
      	   $bline="brvalue_$rname $node1 $node2 i=v($node1,$node2)/($rexpr)";
      	   splice(@deck,$i,1,$bline);
        }
    }
}
sub cl_expressions {
    my ($i,$qexpr,$fluxexpr,$cnt);
    my ($node1,$node2,$cc,$bline1,$bline2,$cline,$lline,$gline,$eline);
    # l1 1 0 flux=expr
    # c1 1 0 q=expr
    $cnt=0;
    for ($i=1;$i<@deck;$i++) {   # for the whole deck
      $_=$deck[$i];
      if(m/^[cl]/i) {
          if(s/\bflux\b\s*\=(.*)//i) { # search for flux = expr
  	       $cc=0;$cnt++;
  	       $fluxexpr=$1;
  	       s/(^[l])(\S+)\s+(\S+)\s+(\S+)//;
  	       $node1=$3;
  	       $node2=$4;
  	       $fluxexpr=~s/ic\=(.*)$//;
               $cc=$1;
  	       if(not$cc) {$cc=0;}
  	       $eline="eflux$cnt $node1 $node2 vflux$cnt 0 1";
  	       $bline1="bfluxa$cnt 0 vflux$cnt i=v(flux$cnt)";
  	       $lline="lflux$cnt vflux$cnt 0 1";
  	       $bline2="bfluxb$cnt flux$cnt 0 v=$fluxexpr";
  	       splice(@deck,$i,1,$eline,$bline1,$lline,$bline2);
  	       $i=$i+3;
          }
    	  elsif(s/\bq\b\s*\=(.*)//i) { # search for flux = expr
    	       $cc=0;$cnt++;
    	       $qexpr=$1;
    	       s/(^[c])(\S+)\s+(\S+)\s+(\S+)//;
    	       $node1=$3;
    	       $node2=$4;
    	       $qexpr=~s/ic\=(.*)$//;
                   $cc=$1;
    	       if(not$cc) {$cc=0;}
    	       $gline="gqexpr$cnt $node1 $node2 vqexpr$cnt 0 1";
    	       $bline1="bqexpra$cnt 0 vqexpr$cnt i=v(qexpr$cnt)";
    	       $lline="lqexpr$cnt vqexpr$cnt 0 1";
    	       $bline2="bqexprb$cnt qexpr$cnt 0 v=$qexpr";
    	       splice(@deck,$i,1,$gline,$bline1,$lline,$bline2);
    	       $i=$i+3;
         }
      }
   }
}


sub poly_2_bdevice {

    my ($i,$j,$k,$found,$firstsum,$firstproduct,@w,$controls,$polydegree);
    my (@exp,@coeff,@inputs,$exp2,$num_coeffs,$num_inputs,$product,$sum);
    my ($cnt,$what,$node1,$node2,$cc,$bline1,$bline2,$cline,$lline,$gline,$eline,$icline,@pms);
    my ($first,$params,$tmpparams);
    # for eg 1 0 poly(2) (xa+,xa-) (xb+,xb-) p0 p1 p2 p3 ...
    # for fh 1 0 poly(2) vnama vnamb p0 p1 p2 p3 ...
    # for c/l 1 0 poly p0 p1 p2 p3 ...  ic=val
    $cnt=0;
    for ($i=1;$i<@deck;$i++) {    # for the whole deck
       $_=$deck[$i];$found=0;@coeff=();@inputs=();
       if(m/\bpoly/i) { # search for poly
          if(m/^[eg]/) {      # e1 1 0 poly(2) (xa+,xa-) (xb+,xb-) p0 p1 p2 p3 ...
                              # be1 1 0  v=f(v(xa),v(xb))
                              # bg1 1 0  i=f(v(xa),v(xb))
      	     $found=1;
      	     s/\bpoly\((\d+)\)//i; # get num_inputs and delete poly(n)
      	     $num_inputs=$1; # now line is like : e1 1 0 xa+ xa- xb+ xb- p0 p1 .....
             s/[\(\)\,]/ /g; # search for ( , ) and replace with blanc
      	     @w = split(' ');
      	     $num_coeffs = $#w-$num_inputs*2-2; # $#w = last index of @w
      	     for ($j=0;$j<$num_coeffs;$j++) { # for all p's
      	         $coeff[$j]=$w[$j+$num_inputs*2+3]; # get the p's p0 p1 p2 ....
      	     }
             for ($j=0;$j<$num_inputs;$j++) { # for all controlling nodes
      	         # w [3 5 7 .. ]   w [4 6 8 .. ]
      	   	 $inputs[$j]="v($w[3+2*$j],$w[4+2*$j])"; # get the next 2 pins = one differential port
      	     }
          }
          elsif(m/^[fh]/) {       # f1 1 0 poly(2) vnama vnamb p0 p1 p2 p3 ......idx=9  degree=3 controls=2
          	                     # bf1 1 0 i=f(i(vnama),i(vnamb))
          	                     # bh1 1 0 v=f(i(vnama,i(vnamb))
             $found=1;
             s/\bpoly\((\d+)\)//i; # get num_inputs and delete poly(n)
      	     $num_inputs=$1; # now line is like :  f1 1 0 vnam1 vnam2  p0 p1 .....
      	     @w = split(' ');
      	     $num_coeffs = $#w-$num_inputs-2; # $#w = last index of @w
     	     for ($j=0;$j<$num_coeffs;$j++) { # for all p's
      	         $coeff[$j]=$w[$j+$num_inputs+3]; # get the p's p0 p1 p2 ....
      	     }
      	     for ($j=0;$j<$num_inputs;$j++) { # for all controlling nodes
      	   	 $inputs[$j]="i($w[3+$j])"; # i(vnam)
      	     }
          }
          elsif (s/(^[cl])(\S+)\s+(\S+)\s+(\S+)\s+\bpoly\b//i) { # c/l poly detected     c1 1 2 poly 1 1 1 0 ic=val -> 1 1 1 0 ic=val
      	     $cnt++;
      	     $what=$1; # c or l
      	     $node1=$3;
      	     $node2=$4;
      	     s/ic\=(.*)$//; # now only 1 1 1 0
      	     $cc=$1;
      	     @pms=split(); # 1 1 1 0   coeffs
	     if($what eq 'c') { # c-device
	     	 $first=1;
		 $gline="gcpoly$cnt $node1 $node2 vcpoly$cnt 0 1";
		 $bline1="bcpolya$cnt 0 vcpoly$cnt i=v(cpoly$cnt)";
		 $lline="lcpoly$cnt vcpoly$cnt 0 1";
		 $bline2="bcpolyb$cnt cpoly$cnt 0 v=";
		 $j=1;
		 foreach $params (@pms) {
		    if(not $first) { $bline2.="+"; }
		    $first=0;
		    if(not $params eq 0) {
			$tmpparams=$params/$j; # if the name is $params it is evaluated in place !!!!! ( @pms is changed )
			if ($j eq 1) {$bline2.="$tmpparams*v($node1,$node2)";}
			else  {
				$bline2.="$tmpparams*v($node1,$node2)^$j";
			}
		    }
		    $j++;
		 }
		 if($cc) { # initial conditions present
		    $bline2.="+v(vic$cnt)";
		    $icline="bic$cnt vic$cnt 0 v=";
		    $j=1;
		    foreach $params (@pms) {
			if(not $params eq 0) {
			     $tmpparams=$params/$j; # if the name is $params it is evaluated in place !!!!! ( @pms is changed )
			     if ($j eq 1) {$icline.="-($tmpparams)*$cc";}
			     else {
				     $icline.="-($tmpparams)*($cc)^$j";
			     }
			}
			$j++;
		    }
		    splice(@deck,$i,1,$gline,$bline1,$lline,$bline2,$icline);
		    $i=$i+4;
	 	 }
		 else {
		   splice(@deck,$i,1,$gline,$bline1,$lline,$bline2);
		   $i=$i+3;
		 }
	     }
	     else { # l-device
		  $first=1;
                  $eline="elpoly$cnt $node1 $node2 vlpoly$cnt 0 1";
                  $bline1="blpolya$cnt 0 vlpoly$cnt i=v(lpoly$cnt)";
                  $lline="llpoly$cnt vlpoly$cnt 0 1";
                  $bline2="blpolyb$cnt lpoly$cnt 0 v=";
                  $j=1;
                  foreach $params (@pms) {
		     if(not $first) { $bline2.="+";}
		     $first=0;
	                if(not $params eq 0) {
			    $tmpparams=$params/$j; # if the name is $params it is evaluated in place !!!!! ( @pms is changed )
			    if ($j eq 1) {$bline2.="$tmpparams*i(elpoly$cnt)";}
			    else {
			       $bline2.="$tmpparams*i(elpoly$cnt)^$j";
			    }
			}
			$j++;
		  }

                  if($cc) { # initial conditions present
                     $bline2.="+v(vic$cnt)";
		     $icline="bic$cnt vic$cnt 0 v=";
		     $j=1;
		     foreach $params (@pms) {
		        if(not $params eq 0) {
		            $tmpparams=$params/$j; # if the name is $params it is evaluated in place !!!!! ( @pms is changed )
                            if ($j eq 1) {$icline.="-($tmpparams)*($cc)";}
			    else {
	                       $icline.="-($tmpparams)*($cc)^$j";
                            }
			}
                        $j++;
		     }
                     splice(@deck,$i,1,$eline,$bline1,$lline,$bline2,$icline);
		     $i=$i+4;
		  }
                  else {
		     splice(@deck,$i,1,$eline,$bline1,$lline,$bline2);
                     $i=$i+3;
		  }
	       }
          }
          else { # no l-device no c-device -> cannot be true
               print "\nSyntax error on poly line;  line must start with literal e,f,g,h or l,c \n" ;exit(1);
          }

          if($found) { # now generate the b-line from efgh polyline
            $sum="";$product="";$firstsum=1;$firstproduct=1;
            @exp=();
            # zero out all exponentials , element 0 is not touched at all
            for($j = 1 ; $j <= $num_inputs; $j++) {
    		     $exp[$j]=0;
            }
            if ( $w[0]=~/^[eh]/i) {$sum=$sum."b$w[0] $w[1] $w[2] v=";}
            else {$sum=$sum."b$w[0] $w[1] $w[2] i=";}
            #/* Compute the output of the source by summing the required products */
            ########################################################################
    	    if($coeff[0]) {$sum.="$coeff[0]";$firstsum=0;}
            for($j = 1 ; $j <= $num_coeffs; $j++) {
     		# /* Get the list of powers for the product terms in this term of the sum */
        	&nxtpwr(\@exp,$num_inputs);
                $firstproduct=1;
                if($coeff[$j]) {# if related p is not zero
        	   # /* Form the product of the inputs taken to the required powers */
                  for($k = 0; $k < $num_inputs; $k++) {
       		      if($exp[$k+1]) { # if not zero a^0 = 1 not used
                          if(not $firstproduct) {$product=$product."*";}
                          $firstproduct=0;
                          $exp2="";
            		  if($exp[$k+1]>1) {$exp2="^$exp[$k+1]";}  # a^1 = a
            		  $product.="$inputs[$k]$exp2";
            	      }
            	  }
                  #/* Add the product times the appropriate coefficient into the sum */
                  if(not $firstsum) {$sum=$sum."+";}
                  $firstsum=0;
                  $firstproduct=1;
                  $sum=$sum."$coeff[$j]*$product";
                  $product="";
               }
            }
            #########################################################################
            $deck[$i]=$sum; # now replace polyline with equivalent b-line
          }
       }
    }
}

sub nxtpwr # translated from the original spice2 fortran code
{          # NOTE: pwrseq is a variable by reference

        local (*pwrseq,$pdim)=@_;

        my($i,$k,$km1,$psum);

        if($pdim == 1) {goto stmt80;}
        $k = $pdim;
stmt10: if($pwrseq[$k]!= 0) {goto stmt20;}
        $k = $k - 1;
        if($k != 0) {goto stmt10;}
        goto stmt80;
stmt20: if($k == $pdim) {goto stmt30;}
        $pwrseq[$k] = $pwrseq[$k] - 1;
        $pwrseq[$k+1] = $pwrseq[$k+1] + 1;
        return;
stmt30: $km1 = $k - 1;
        for($i = 1; $i <= $km1; $i++)
        {
           if($pwrseq[$i] != 0) {goto stmt50;}
        }
        $pwrseq[1] = $pwrseq[$pdim] + 1;
        $pwrseq[$pdim] = 0;
        return;
stmt50: $psum = 1;
        $k = $pdim;
stmt60: if($pwrseq[$k-1] >= 1) {goto stmt70;}
        $psum = $psum + $pwrseq[$k];
        $pwrseq[$k] = 0;
        $k = $k - 1;
        goto stmt60;
stmt70: $pwrseq[$k] = $pwrseq[$k] + $psum;
        $pwrseq[$k-1] = $pwrseq[$k-1] - 1;
        return;
stmt80: $pwrseq[1] = $pwrseq[1] + 1;

stmt100: return;

}

sub funcline_paramline_relational_op {
    my ($i,$j,$found,$relpat,$relpat2,$pat,$left,$right,$leftexpr,$rightexpr,$temp,$searchexp,$replaceexp,$replaceexp2,$lex);
    my ($openp,$closep);
    my @relpats=('<=','>=','<','>','==','!=','&&','||','!'); # never let '<' '>' be before '<=' or '>=' !!!
    my %convert=('<','lt','>','gt','<=','le','>=','ge','==','eq','!=','ne','&&','and','||','or','!','not');
    #  $tinylines;    if set to 0 every replacing is done to the same b-line
    #                 if set to 1 splitting each relational op expression into a own b-line
    for ($i=1;$i<@deck;$i++) {  # for the whole deck
       $_=$deck[$i]; # current line
       if ( /^\.func/ ) { # search for .funclines , paramlines handled by perl itself
          $j=0;
          foreach $relpat (@relpats) {
             $pat=quotemeta($relpat);
             if($relpat eq '||') {$relpat2='(.*?)'.'(\|\|)'.'(.*)';} # special treatment for ||
             else {
               $relpat2='(.*?)'."($pat)".'(.*)'; # $1=before,$2,$3=behind
             }
             while(/$relpat2/) {
               $right=$3;
               $found=$2;
               $left=$1;
               $j++; # another expression detected
               if($relpat eq '!') {
                  $left='';
               }
               else  {
                 $left=reverse($1);
               }
               $leftexpr='';$rightexpr='';
               if($left) { # the left side is managed first
                           # expression may be a numeric , parametername , function , paranthesis exor
                           # 0) 3.44>= , 1) par1< , 2)  myf(a,b)< , 3)  2*((a)<
                  $_=$left;
                  s/^\s*//; # no leading blanks
                  if(/^([0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)\b/) { # 0)
                  #if(/^([0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)/) { # 0)
                  #if(/^(\d+\.\d+|\d+)/) { # 0)
                    $leftexpr=$leftexpr.$1;
                  }
                  else {
                     if(/^(\))/g) { # 2)3)
                        $openp=0;$closep=1;
                        $leftexpr=$leftexpr.')';
                        while($closep>$openp) {
                           /(.*?)([\(\)])/g; # search for opend or closed paranthesis
                           $leftexpr=$leftexpr.$1.$2;
                           if($2 eq ')') {$closep++;}
                           else {$openp++;}
                        }
                        $lex=quotemeta($leftexpr);
                        s/$lex//;
                     }
                     if(/^\s*(\w+)/) { # 1)
                        $leftexpr=$leftexpr.$1; # append it
                     }
                  }
                  $leftexpr=reverse($leftexpr);
               }
               $_=$right; # the right side is now managed
                          # 0) <=3.444  1) >par1 , 2) <myf(a,b) , 3) >=(2*(a))
               s/^\s*//; # no leading blanks
               if(/^([0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)\b/) { # 0)
                  $rightexpr=$rightexpr.$1;
               }
               else {
                 if(s/^(\w+)\s*//g) {$rightexpr=$rightexpr.$1;} # 1)
                 if(/^(\()/g) { # 2)3)
                   $openp=1;$closep=0;
                   $rightexpr=$rightexpr.'(';
                   while($openp>$closep) {
                     /(.*?)([\(\)])/g; # search for opend or closed paranthesis
                     $rightexpr=$rightexpr.$1.$2;
                     if($2 eq ')') {$closep++;}
                     else {$openp++;}
                   }
                 }
               }
               $temp=$convert{$relpat};
               if($left) {
                 $searchexp=quotemeta($leftexpr.$relpat.$rightexpr);
                 $replaceexp=$temp.'('.$leftexpr.','.$rightexpr.')';
               }
               else {
                 $searchexp=quotemeta($relpat.$rightexpr);
                 $replaceexp=$temp.'('.$rightexpr.')';
               }
               $deck[$i] =~ s/$searchexp/$replaceexp/; # writeback to the same line !!!!!
               $_=$deck[$i]; # reinit it
            }
         }
       }
    }
}

sub b_device_relational_op {   # new new new new new new
    my ($i,$j,$bname,$found,$relpat,$relpat2,$pat,$left,$right,$leftexpr,$rightexpr,$temp,$searchexp,$replaceexp,$replaceexp2,$lex);
    my ($openp,$closep);
    my @relpats=('<=','>=','<','>','==','!=','&&','||','!'); # never let '<' '>' be before '<=' or '>=' !!!
    my %convert=('<','lt','>','gt','<=','le','>=','ge','==','eq','!=','ne','&&','and','||','or','!','not');
    #  $tinylines;    if set to 0 every replacing is done to the same b-line
    #                 if set to 1 splitting each relational op expression into a own b-line
    if($xornot) {
        $relpats[9]='~';  # ~
        $relpats[10]='^'; # ^
        $convert{'~'}='not';
        $convert{'^'}='xor';
    }
    for ($i=1;$i<@deck;$i++) {   # for the whole deck
       $_=$deck[$i]; # current line
       if ( /^b(\w*)/ ) { # search for b[name]
          $bname=$1;
          if($ltspice) {
            s/\^/\*\*/g;
          }
          else {
            $deck[$i]=~s/\*\s*\*/\^/g; # a**b or a * *b
          }
          $j=0;
          foreach $relpat (@relpats) {
              $pat=quotemeta($relpat);
              if($relpat eq '||') {$relpat2='(.*?)'.'(\|\|)'.'(.*)';} # special treatment for ||
              else {
                 $relpat2='(.*?)'."($pat)".'(.*)'; # $1=before,$2,$3=behind
              }
              while(/$relpat2/) {
                 $right=$3;
                 $found=$2;
                 $left=$1;
                 $j++; # another expression detected
                 if($relpat eq '!' || $relpat eq '~') {
                    $left='';
                 }
                 else {
                    $left=reverse($left);
                 }
                 $leftexpr='';$rightexpr='';
                 if($left) {  # expression may be a numeric , parametername , function , voltage or current , paranthesis
                              # 0) 4.224e12>=  1) par1< , 2) myf(a,b)< , 3) v(a,b)> , 4) 2*((a)<
                    $_=$left; # the left side is managed
                    s/^\s*//; # no leading blanks
                    if(/^([0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)\b/) { # 0)
                         $leftexpr=$leftexpr.$1;
                    }
                    else {
                       if(/^(\))/g) { # 2)3)4)
                          $openp=0;$closep=1;
                          $leftexpr=$leftexpr.')';
                          while($closep>$openp) {
                            /(.*?)([\(\)])/g; # search for opend or closed paranthesis
                            $leftexpr=$leftexpr.$1.$2;
                            if($2 eq ')') {$closep++;}
                            else {$openp++;}
                          }
                          $lex=quotemeta($leftexpr);
                          s/$lex//;
                       }
                       if(/^\s*(\w+)/) { # 1)
                          $leftexpr=$leftexpr.$1; # append it
                       }
                    }
                    $leftexpr=reverse($leftexpr);
                 }
                 $_=$right; # the right side is now managed
                            # 1) >par1 , 2) <myf(a,b) , 3) <v(a,b) , 4) <(2*(a))
                 s/^\s*//; # no leading blanks
                 if(/^([0-9]*\.?[0-9]+(?:[eE][-+]?[0-9]+)?)\b/) { # 0)
                    $rightexpr=$rightexpr.$1;
                 }
                 else {
                    if(s/^(\w+)\s*//) {$rightexpr=$rightexpr.$1;} # 1)
                    if(/^(\()/g) {   # 2)3)4)
                       $openp=1;$closep=0;
                       $rightexpr=$rightexpr.'(';
                       while($openp>$closep) {
                          /(.*?)([\(\)])/g; # search for opend or closed paranthesis
                          $rightexpr=$rightexpr.$1.$2;
                          if($2 eq ')') {$closep++;}
                          else {$openp++;
                          }
                       }
                    }
                 }
                 $temp=$convert{$relpat};
                 if($left) {
                     $searchexp=quotemeta($leftexpr.$relpat.$rightexpr);
                     $replaceexp=$temp.'('.$leftexpr.','.$rightexpr.')';
                     # if tinylines
                     $replaceexp2 = 'v(b'.$bname."_".$temp.$j.')';
                 }
                 else {
                     $searchexp=quotemeta($relpat.$rightexpr);
                     $replaceexp=$temp.'('.$rightexpr.')';
                     # if tinylines
                     $replaceexp2 = 'v(b'.$bname."_".$temp.$j.')';
                 }
                 if($tinylines) {
                     $deck[$i] =~ s/$searchexp/$replaceexp2/; # split into another b-line  !!!!!
                     splice(@deck,$i+1,0,"b$bname"."_"."$temp$j b$bname"."_"."$temp$j  0 v=$replaceexp");
                 }
                 else {
                     $deck[$i] =~ s/$searchexp/$replaceexp/; # writeback to the same line !!!!!
                 }
                 $_=$deck[$i]; # reinit it
              }
          }
       }
    }
}
sub table2bh {
  my ($i,$n,$m,$lenbh,$name,$type,$pos,$neg,$expr);
  my (@x,@y,@bh,@kill);

  for ($i=1;$i<@deck;$i++) {    # for whole deck
     $_=$deck[$i];
     if (m/^([efgh])/i ) { # efgh-source
        if(m/table/i) { # efgh-table source
            $m=-1;@bh=();@x=();@y=();
            @kill=(); # reset it
            m/^([efgh])([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+table[^\{]*\{([^\}]+)\}\s*\=(.*)/i; # name pos neg table {expr} = (,) (,)
            $type = $1;$name = $2;$pos = $3;$neg = $4;$expr = $5;
            $_ = $6;
            while ( m/\(([^,]+),([^\)]+)\)(.*)/i ) {
               $m++;
               $x[$m]=$1;
               $y[$m]=$2;
               $_ = $3; # rest
            }
            # shure is shure last table value extended 100 times
            #$m++;
            #$x[$m]=$x[$m-1]+$x[$m-1]*100;
            #$y[$m]=$y[$m-1];
            # now everything is extracted and the vars are stored
            # ================ generate new lines for b-table
            $bh[0]= "* conversion of pspice table to xspice - core model";
            $bh[1]= "b1g"."$type$name "." xg"."$type$name"." 0 v=".$expr;
            $bh[2]= "a1g"."$type$name "." xg"."$type$name"." yg"."$type$name"." table_g"."$type$name";
            $bh[3]= "v1g"."$type$name "." yg"."$type$name"." 0 0";
            if($type eq "e" || $type eq "h") {
               $bh[4]= "h1g"."$type$name "." ".$pos." ".$neg." v1g"."$type$name"." 1";
            }
            else {
               $bh[4]= "f1g"."$type$name "." ".$pos." ".$neg." v1g"."$type$name"." 1";
            }
            $bh[5]= ".model table_g"."$type$name "." core area=1 length=1 h_array=[ ";
            #first value is special
            $bh[5].="-1.0e12 ";
            for ($n=0;$n<=$m;$n++) {
              $bh[5] .= $x[$n]." ";
              #if (n<m) {$bh[5] .= ","; }
            }
            # last value is special
            $bh[5].=" 1e12";
            $bh[5] .= " ] b_array=[ ";
            #first value is special
            $bh[5].=$y[0]." ";
            for ($n=0;$n<=$m;$n++) {
                 $bh[5] .= $y[$n]." ";
                 #if (n<m) {$bh[5] .= ","; }
            }
            # last value is special
            $bh[5].=" ".$y[$m];
            $bh[5] .= " ]";
            $bh[6] = "* conversion end";
            # ================ ende generiere neue Zeile f�r b-table
            push @kill,$i;
            splice(@deck,$i+1,0,@bh);   # insert new lines forb-table started with act. i
            &zapdeck(@kill); # delete line    gname pos neg ....
            $lenbh=@bh;
            $i=$i+$lenbh-1;
        } # no table
     }  #no efgh-source
  } #next i
}
sub table2bh_spice3 {
  my ($i,$n,$m,$p,$q,$lasti,$name,$type,$pos,$neg,$expr,$lenall);
  my (@x,@y,@all,@bh,@pmx,@pmy,@pmk,@pmd,@kill,$cntxy,$cntex);

  # reset conter for spice3-table sources
  $cntxy=0;$cntex=0;
  @kill=();

  for ($i=1;$i<@deck;$i++) {    # for whole deck
    $_=$deck[$i];
    if (m/^(g|f|h|e)/i ) { # g-source
       if(m/table/i) { # new gfhe-table detected
          #init
          $lasti=$i; # position of the last table source
          @kill=();@all=();$m=-1;@bh=();@x=();@y=();@pmx=();@pmy=();@pmk=();@pmd=();
          m/^(g|f|h|e)([^\s]+)\s+([^\s]+)\s+([^\s]+)\s+table[^\{]*\{([^\}]+)\}\s*\=(.*)/i; # name pos neg table {expr} = (,) (,)
          $type = $1;$name = $2;$pos = $3;$neg = $4;$expr = $5;
          $_ = $6;
          while ( m/\(([^,]+),([^\)]+)\)(.*)/i ) { # reads in x,y pairs
             $m++;
             $x[$m]=$1;
             $y[$m]=$2;
             $_ = $3; # rest
          }
          # now everything is extracted and the vars are stored
          # ================ generate new lines for b-table
          $q=0;
          for ($n=$cntxy;$n<=($m+$cntxy);$n++) { # x,y pairs as parameters
             $pmx[$q]=".param x".$n."="."$x[$q]";
             $pmy[$q]=".param y".$n."="."$y[$q]";
             $q++;
          }
          $q=0;
          for ($n=$cntxy;$n<($m+$cntxy);$n++) { # k,d formula as parameter ( nr. of x,y-pairs - 1 )
             $pmk[$q]=".param k".$n."={(y".($n+1)."-y".$n.")/(x".($n+1)."-x".$n.")}";
             $pmd[$q]=".param d".$n."={y".$n."-k".$n."*x".$n."}";
             $q++;
          }
          $bh[0]= "* conversion of pspice table to spice3 bsource model start ... ";
          # all parameters !!!!!!
          $bh[1]= "b$type"."ex".$name." ex".$cntex." 0 v=".$expr;  # one expression line
          $q=2;
          # first line is special
          # bx0y0 x0y0 0 v=LT(v(ex1),x0)*d0
          $n=$cntxy;
          $bh[$q]="b$type"."x".$n."y".$n." x".$n."y".$n." 0 v=lt(v(ex".$cntex."),x".($n).")*".$y[0];
          $q=3;
          for ($n=($cntxy);$n<=($m+$cntxy-1);$n++){ # one b-source line for one x,y pair !!!
             # bx1y1 x1y1 0 v=GE(v(ex1),x0)*LT(v(ex1),x1)*(k0*v(ex1)+d0)
             # bx2y2 x2y2 0 v=GE(v(ex1),x1)*LT(v(ex1),x2)*(k1*v(ex1)+d1)
             # .....
             $bh[$q]="b$type"."x".($n+1)."y".($n+1)." x".($n+1)."y".($n+1)." 0 v=ge(v(ex".$cntex."),x".$n.")*lt(v(ex".$cntex."),x".($n+1).")*(k".$n."*v(ex".$cntex.")+d".$n.")";
             $q++;
          }
          # last line is special
          # bx8y8 x8y8 0 v=GE(v(ex1),x8)*d7
          $n=$m+$cntxy+1;
          $bh[$q]="b$type"."x".$n."y".$n." x".$n."y".$n." 0 v=ge(v(ex".$cntex."),x".($n-1).")*".$y[$m];
          $q++;
          if($type eq "e" || $type eq "h") { # ouputline prefix = v or i
             $bh[$q]= "b$type".$name." ".$pos." ".$neg." v=";
          }
          else { # f and g source -> ouput = i
             $bh[$q]= "b$type".$name." ".$pos." ".$neg." i=";
          }
          for ($n=$cntxy;$n<=($m+$cntxy+1);$n++) { # one output line = sum of all ouputs
             $bh[$q].="v(x".$n."y".$n.") +"; # append v(xn,yn) + .....
          }
          chop($bh[$q]); # eats last +
          $bh[($q+1)] = "* table conversion end.";
          # ================ ende generiere neue Zeile f�r b-table
          push(@all,@pmx);push(@all,@pmy);push(@all,@pmk);push(@all,@pmd);push(@all,@bh);
          push @kill,$i;
          if(@kill) {
            &zapdeck(@kill); # delete line    gname pos neg ....
            splice(@deck,$lasti,0,@all);   # insert new lines for b-table(s) started with act. i
          }
          $cntxy+=$m+2; # update counter for nr. of x,y pairs to handle another table model
          $cntex++;   # update counter for nr. of table models
          $lenall=@all;
          $i=$i+$lenall-1;
          } # end if table
       } # end if efgh-source
   } #end for i
}
sub time2vtime {
  my ($i,$tmp,$x3,$x2,$uic,$steptime);
  my (@time,@tranline);

  @time=();
  $x3=0; # starttime=0 default
  for ($i=1;$i<@deck;$i++)  {  # for whole deck
     $_=$deck[$i];
     if (m/^\.tran/i) {  # .tran tstep tstop tstart minstep [uic]
        if(s/\buic\b//) {$uic="uic";}
        else {$uic="";} # delete additional "uic" statement if present
      	@tranline=split( /\s+/,$_);
        if($#tranline<2) { # only endtime given .tran tstop
           $x2= &unit($tranline[1]); # stoptime
           $steptime = $x2/20; # default
      	   $deck[$i]=".tran $steptime $x2 $uic"
        }
        else { # .tran tstep tstop
      	  $x2 = &unit($tranline[2]); # stoptime
          if($#tranline>2) { # .tran tstep tstop tstart ...
             $x3 = &unit($tranline[3]); } # starttime given (default=0s)
        }
        $time[0]="vtime times 0 pwl ".$x3."s ".$x3."v ".$x2."s ".$x2."v dc 0";
        splice(@deck,$i,0,@time);
        return; # we are now done
     }
  }
}

#read_parameters ( read in parameter defined lines e.g: .param a=4 b={a*3} c=3*myfunc(2*3) ....  and delete them)
sub read_parameters {
  my ($i,$j,@kill,$temp1,$temp2);
  #################### new ###################
  #%param=(); # is a global variable !!!!
  for ($i=1;$i<@deck;$i++) {              # whole inputdeck $deck [0] [1] ... a.s.o all Inputlines
    if ($deck[$i] =~/\.param\s+(.*)/) {  # record param/value pairs ; search for .param statement $1 = rest
      push @kill,$i;
      $_=$1;
      $done=0;
      until ($done) {
        if (/^\s*(\S+)\s*\=\s*\{([^\}]*)\}(.*)/) {  # search for  VAR = { Expression }
          # $1 = Variable  $2 = { .... }  $3 = Rest
          $_=$2;
          $temp1 = $1;
          $temp2 = $3;
          # now all parameternames should be space delimited
          $param{$temp1}=$_;   # stores param to hash
          $_=$temp2;  # is another param present ?
        }
        elsif (/^\s*(\S+)\s*\=\s*(\S+)(.*)/) {  # search for  Var = value  ( $1 = Var , $2 = num. Value, $3 is rest  )
         $param{$1} = &unit($2); # stores param to hash , convert m,u,p,f,k,MEG,t, ....
         $_=$3;  # is another param present ?
        }
        else { $done=1; }
      }
    }
  }
  &zapdeck(@kill);
}

# evaluates RHS (right hand side) of parameter definitions to a pure numerical value
# .param b = {a/4} -> subs a with numerical value and eval b
sub eval_parameters {
  my ($val, $nval, $paramkeys);

  $param{"time"}="0"; # only param with notnumerical val

  for $paramkeys (keys %param) {   # for all param in list do
      $val=$param{$paramkeys};       # paramval e.g.   3 * a + 5 * b + c
      if(&isnumber($val)) {}
      else
      {
        $nval=&process($val);       # eval the expression now
        if(!defined($nval)) {
            print "\n\nerror -> paramname: $paramkeys  value: $val\n";
            &hint;
            exit(1);
        }
        $param{$paramkeys}=$nval;   # write back pure numerical to parameterhash
      }
  }
  $param{"time"}="V(TIMES)"; # only param with notnumerical val
}

# search for parameternames in all lines of the deck
# b - lines -> search/replace parameternames -> eval is done by spice itself
# all other lines ->  search/replace/eval if parameterexpression with paranthesis present e.g. { p1+2*p2+5 } -> val
sub expand_parameters {

  my ($i,$j,$start,$nline,@line,@start,$val,$key,$nstart);
  my ($head,$temp,$nval,$tail);

  for ($i=1;$i<@deck;$i++) {         #  for whole deck
    $_=$deck[$i];
    if(m/^b/) {  # b-line
        @line=split(/\s+/,$deck[$i]);
        @start=splice(@line,0,3); # @start = "b1 1 0 " = the first 3 items are not parametersubstituted
                                  #   @line->$nline -> ready for parametersubstitution
        $nstart=join " ",@start;
        $nline=join " ",@line;
        # search and replace parameters in b-lines ( dont replace nodenames and vsrcnames v(name[,name]),i(vsrcname) )
        foreach $key (keys %param) {
            $val=$param{$key};
            $key=quotemeta($key);
            # if v(node1,(node2)) or i(vnam) -> convert to upper case
            $nline=~s/(\b[vi]\s*\([^\)]+\))/uc($1)/eg;  #search v(x) or i(x) and replace with upper case letters
            $nline=~s/\b$key\b/$val/g; # case sensitive substitiution -> only lowercase
            #$nline=lc($nline); # for better appearance no lower case again
        }
        # do some hacks for b-lines
        $nline =~ s/\s+//g;   # delete blanks in expression from subcktexpansion
        $nline =~ s/\*\*/\^/g;   # search for ** and subs with ^
        $nline.="+v(0)"; # add v(0) will prevent some simulators to come away with fixvalued b-sources
        $deck[$i]=$nstart." ".$nline; # write back
    }
    elsif (m/\{/) { # r,l,c,... one expr
                  # .model .tran  .dc  ... maybe one or more {expr} present in line
           $nline="";
           while (/([^\{]*)\{([^\}]*)\}(.*)/) {
    	      # parameterexpr with { } present in deviceline
              $head=$1; $tail=$3;
              $temp=$2;
      	      $nval=&process($temp);
      	      if(!defined($nval)) {
                  print "\n\n..... $deck[$i-1]\n";
                  print "error -> line: $i -> $deck[$i]\n";
                  print "..... $deck[$i+1]\n";
                  &hint;
      	          exit(1);
      	      }
      	      $nline .= $head.$nval;
              $_=$tail; # perhaps another param in line ?
           }
           $nline .= $_;  # rest
           $deck[$i]=$nline; # write back
    }
    else {} # do nothing -> this line has no parameters
  }
}
# process rhs of .param expressions to a pure numerical values
# e.g. rhs = 3*a+5/b  replace a,b with their numerical value (or other expression->recursively) unitl
# rhs is a expression with pure numerical values  -> then eval the expression
# The detection is done by always make one additonal loop with all parameternames
# If a whole loop's search/replace count is zero ($found=0) -> the line should now be a pure numerical value or expression
# e.g. rhs = 3*(2*(4+5)+5/(2*(3+5)))
sub process {
 my ($nline,$r,$i,$n,$found);

 $nline = $_[0];
 $found=1;

 while ($found>=1)
 { # while another parameter present  - nested
   $found=0;
   foreach $key (keys %param)
   {
         $val=$param{$key};
         $key=quotemeta($key);
         $found+=$nline=~s/\b$key\b/\($val\)/g;   #search and replace it "NOTE: set $val in paranthesis !!!!!!!!"
   }
 }
 $nline =~ s/\s+//g;   # perl eval dont like blanks in expressions -> delete them
 $nline =~ s/--/+/g;   # perl eval dont want -- in expressions -> substitute it by +
 # sometimes pspice users use spiceunits in expressions {frequ1/n2*1u}->{50/2*1u}->{50*2*1e-006}
 $nline =~ s/\b([0-9\.]+(t|g|meg|k|mil|m|u|n|p|f)(v|a|s|f|ohm|h|w|hz|va)?)\b/unit($1)/eg;
 # sometimes pspice users use nested {} inside {}'s -> error
 $nline = "1.0*(".$nline.")"; # helps perl to treat it as numeric !!!!
 $r=eval($nline);      # TEST: Evaluates pure numerical expression ( e.g. a is "2*3" and  b is "3*a+2" -> b=3*(2*3)+2 -> b=20 )
 if($@) {
     print "\nerror evaluating expression expr: \n\n$nline : $@ -> please check\n\n";
 }
 return ($r);            # returns only numerical val. or undef
}

sub hint {
     print "\nHINTs: If you detect curly braces in the expression: -> because of nested curly braces in the cirfile ";
     print "\n       find and substitute all inner curly braces through round braces\n";
     print "\n       If the error says : Division by zero:";
     print "\n       This may occur in .param lines in conjunction with the if() function ";
     print "\n       e.g: .param b=10  a={IF(b,0,bn)}  c={1/a}";
     print "\n       Search the bad term and add a very small value to it (1/a) -> (1/(a+eps))";
     print "\n       Add the line .param eps=1e-20 to the cirfile\n";
     print "\n       Try the ps2sp.pl command line option -check -debug";
     print "\n       to check the equal nr. of open and closed paranthesis per line and";
     print "\n       to output the values of all parameters and functions\n";
     print "\n       Check also the intermediate outputfiles lib.tmp and sub.tmp";
     print "\n       lib.tmp shows the original file and the additional external subcircuits included from .lib lines";
     print "\n       sub.tmp shows the subcircuitexpansion with unique parameter and function names";
}

############## read globals ############
# record a hash of all global signals. kill the line.
sub read_globals {
  my ($i,$file,$model,@kill);
  for ($i=0;$i<@deck;$i++) {
    if ($deck[$i] =~ /^\.globals?\s+(.*)/) {
      for (split(' ',$1)) { $globals{$_}=1 }
      push @kill,$i;
    }
  }
  &zapdeck(@kill);
}
############## kill line(s) in deck ################
sub zapdeck {
  # give it a list of lines to remove in increasing order!!!
  # @_ = e.g. 0 1 2 3 -> $_=pop(@_)=3   now @_= 0 1 2
  while ($_=pop(@_)) {
    splice @deck,$_,1;
  }
}
################## add globals to subckt IO line  ######################
# accept subroutine data
# add used global signals to the io defn line
# remember them in $globalsub{sub} to fix other instantiate lines
sub expand_globals{
  my ($i,$extras,$subckt);

  $extras=join(" ", keys %globals);

  for ($i=1;$i<@deck;$i++) {
    $_=$deck[$i];
    if (/^\.subckt\s+(\S+)/) {
      $deck[$i] =~ s/^(.subckt.*)$/$1 $extras/;
    }
    elsif (/^(x.*)\s+(\S+)\s*$/) {
      $deck[$i]="$1 $extras $2\n";
    }
  }
}


####################### control codes #########################
# .tran xxx -> .control tran xxx .endc
# .op xxx -> .control op xxx .endc
# .dc , four , endi , plot , print detto !!!!
sub expand_control  {
  my ($i,@xtra);
  for ($i=1;$i<@deck;$i++) {
    $deck[$i]=~s/^\.backanno/\*\.backanno/i; # new for ltspice
    #$deck[$i]=~s/^\!//; # new for allowing conversion of *$ -> ! controllines
    $_=$deck[$i];
    if (/^\.(plot|print|tran|ac|dc|op|four|endi)\b/) { # this things will be put under   .control .... .endc
      $cmd=$1;
      s/^\.//; # drop initial dot
      s/\stran\s/ /; # "print tran " -> "print "
      s/start=\S+//; # "hspice syntax ? in tranline ? "
      s/([vi])\s*\(\s*(\S+)\s*\)/$1($2)/ig; # i ( vx ) -> i(vx) and  v ( 1 ) -> v(1)
      push(@xtra, ".control");
      if ($cmd eq "endi") {
        push(@xtra, "destroy all" ) unless ($interactive);
        push(@xtra, "quit") unless ($interactive);
      }
      else {
        push(@xtra, $_); # this is the line
      }
      push(@xtra, ".endc");
      splice(@deck,$i,1,@xtra);
      @xtra=();
    }
  }
}

sub fix_temp {
  for ($i=1;$i<@deck;$i++) {
    if ($deck[$i] =~ /^\.tempe?r?a?t?u?r?e?\s*\=\s*(\S+)/)
    {
         $deck[$i] = ".options temp=$1";
         splice(@deck,$i+1,0,".param temp=$1");
	 $i++;
    }
    if ($deck[$i] =~ /^\.options\s+temp\s*\=\s*(\S+)/)
    {
         splice(@deck,$i+1,0,".param temp=$1");$i++;
    }

  }
}
################# translate model level #######
# bsim3 (v3)
sub xlat_level {
  for ($i=1;$i<@deck;$i++) {
    $deck[$i] =~ s/(.*)\blevel\s*=\s*49\b(.*)/$1level=8$2/;
  }
}
sub printdeck {
my ($last);
  $last=pop(@deck); # last element remembered
  push @deck,@probe; # add probelines
  if(@control) {
      push @deck,".control";
      push @deck,@control; # add controllines
      push @deck,".endc";
  }
  push @deck,$last; # now last again
  for (@deck) {
    if($_=~/^\*/) { # if the line is a commentline start wraped line with *
       print &wrapline($wrap,"","*","\n"," ",split(' ',$_));
    }
    else {
       print &wrapline($wrap,"","+","\n"," ",split(' ',$_));
    }
  }
}
sub fprintdeck {
  my $first;
  open (DATEI,"+>$dateiname") || die "Fehler beim Schreiben auf DATEI $dateiname";
  $first=1;
  for (@deck) {
    if($_=~/^\*/) { # if the line is a commentline start wraped line with *
       print DATEI &wrapline($wrap,"","*","\n"," ",split(' ',$_));
    }
    else {
       print DATEI &wrapline($wrap,"","+","\n"," ",split(' ',$_));
    }
  }
  close (DATEI);
}
######################### wrapline ###############
# wrapline( linelen, header, header2, trailer,
#           separator, list )
# where
#  linelen max number of chars per line   eg 70
#  header   is a string stuck on to the beginning
#  header2  is a string to add to the second and all subsequent lines,
#           {if they exist]
#  trailer is a string to tack on to the end of the structure
#  separator is put between multiple elements in the list (NOT last)
#  list
# returns string
sub wrapline {
  my($maxlen, $header, $header2, $trailer,
     $separator, $linelen, @list, $output, $term, $last_term);

  ($maxlen, $header, $header2, $trailer, $separator, @list)=@_;
  $output=$header;
  $linelen=length($output);
  $last_term=pop(@list);
  foreach $term (@list) {
    if ((length($term)+$linelen+length($separator))>$maxlen) {
       $output .= "\n$header2" ;
       $linelen = length($header2);
    }
    $output .= "$term$separator";
    $linelen += length($term)+ length($separator);
  }
  if ((length($last_term)+$linelen+length($trailer))>$maxlen) {
    $output .= "\n$header2" ;
  }
  $output .= "$last_term$trailer";
  return $output;
}
# search for integer , float or exponential number
sub isnumber {
  #if ($_[0] =~ /^\s*[\+\-]?[0-9\.]+\s*$/)
  if ($_[0] =~ /^\s*[\+\-]?[0-9\.]+(t|g|meg|k|mil|m|u|n|p|f)?(v|a|s|f|ohm|h|w|hz|va)?\s*$/)
  {return 1;}
  elsif ($_[0] =~ /^\s*[\+\-]?[0-9\.]+e[\+\-]?\d+$/)
  {return 1;}
  else
  {return 0;}
}
# search for expression in paranthesis -> { ... }
sub isexpression {
  if ($_[0] =~ /^\s*\{.*?\}\s*$/)
  #if ($_[0] =~ /[\{\}]/)
  {return 1;}
  else
  {return 0;}
}
# m=3 can be used to insert 3 parallel instances into the netfile
# need to delete the m= and increment the instance name while copying
# strings
sub expand_parallel  {
  my ($i,$n,$orig,$iname,$dname,$j);
  for ($i=1;$i<@deck;$i++) {
    if ($deck[$i] =~ /\s*m\s*\=\s*(\d+)\s*$/) {
      $n=$1;
      $_=$deck[$i];
      s/ m\s*=\s*($n)//; # remove the m=xx
      /^(\S+)\s/;
      $iname=$1;
      $deck[$i]=$_;
      $orig=$_;
      for ($j=2;$j<=$n;$j++) {
        $_=$orig;
        $dname=$iname . "__" . $j;
        s/$iname/$dname/;
        splice(@deck,$i+$j-1,0,$_);
      }
    }
  }
}
# unit to number
# expressions may have suffix v,a,s,f,ohm,h,w,hz,va
sub unit {
  if ($_[0] =~ /^([0-9e\+\-\.]+)(t|g|meg|k|mil|m|u|n|p|f)?(v|a|s|f|ohm|h|w|hz|va)?$/) {
    if    ($2 eq 't')   { $mult = 1e12 }
    elsif ($2 eq 'g')   { $mult = 1e9  }
    elsif ($2 eq 'meg') { $mult = 1e6  }
    elsif ($2 eq 'k')   { $mult = 1e3  }
    elsif ($2 eq 'm')   { $mult = 1e-3   }
    elsif ($2 eq 'u')   { $mult = 1e-6   }
    elsif ($2 eq 'n')   { $mult = 1e-9   }
    elsif ($2 eq 'p')   { $mult = 1e-12  }
    elsif ($2 eq 'f')   { $mult = 1e-15  }
    elsif ($2 eq 'mil') { $mult = 25.4e-6}
    else                { $mult = 1  }
    return $1 * $mult;
  }
  return $_[0];  # maybe perl does it better??
}
# FOR SUBCIRCUIT expansion:
# when substituting parameters , skip this number from the start
# e.g.  r1 1 0 {R}  skipnr = 3  param is in field nbr. 3 ( three fields skipped )
sub skipnumber {
  my ($line,$f,$n,$len,@words);
  $line=$_[0];
  $_=substr($line,0,1); # get the first char in the line
  $n=tr/bcdefghijklmoqrstuvw/22222222322443244323/; # element nodes list of skipped fields-1
  if ($n == 1) { # found one of the devices above
    return $_+1;   # add the name of the instance to the number of nodes
  }
  $len=@words=split(' ',$line);
  $first=shift(@words);
  if ($first =~ /^x/) { return 2 }   # process this line starting at second element
  if ($first =~ /^\+/) { return 0 }   # full process of continuation lines
  if ($first =~ /^\.model/) { return 3 }   # process this line .. -> only process {expressions}
  { return $len }    # all other lines are not processed
}
# Get a line from the input file, combining any continuation lines into
#   one long line.  Skip comment and blank lines.
#  first line is not skipped
sub prm_getline {
    my($line);
    my($firstline);
    # local($nxtline);
    # $linenum is used for debugging
    # $line = if not defined $nxtline -> first invocation ($linenum=1) $line=<INFILE> else $line=$nxtline
    chop($line = defined($nxtline) ? $nxtline : <INFILE>);
    $linenum = $.; # act. linenumber
    if( not $linenum eq 1 )# new detect first line !! )
    {
      while ($nxtline = <INFILE>) {
        if ($line =~ /^\*|^\s/) { $line = ''; }   # documentation line   * TEXT
        $_ = $line; # NEW ########################## use of  ";" for inline comment
        s/\;.*//;
        $line = $_;
        if ($line eq '' || $nxtline =~ s/^(\+)/ /) {  # blanc line deleted  ,  continuation with  +
            chop($nxtline);                              # Cr deleted
            $line .= $nxtline;                           # and concatanated again at the end
        }
        else { last; }
      }
    }
    $line;
}
# Scan the input file looking for x-calls with parameters , remove and store the parameters
# Also look for subcircuits with defined parameters , store it
# inside a subckt store parameters and .param .func .pfunc -lines
sub prm_scan {
    my(@w, @tmp, @list);
    my($xnm, $subnm, $psubnm,$i,  $m, $s, $n, $tmp,$tmp2, $start,$linestart,$tmpline,$hasprm,$prmline);
    my($sublist) = '';

    $max = 0; # global unique identifier for all x-lines with parameters in the circuit
    $depth=0; # global deepth counter

PRM_SCAN:
    while ($_ = &prm_getline) {  # get new inputline, + lines are flattend
        if (/^\.control/i) {  # skip from  .control to .endc
            while ($_ = &prm_getline) { next PRM_SCAN if (/^\.endc/i); } # till  .endc
        }
        tr/A-Z/a-z/;   # convert line $_ to lowercase
PRM_TST:{
            if (/^x/ && s/params:(.*)//) {   # test if  "x..." Line with parameter  subs /params: ..../ with //
                $prmline=$1;     # NOTE: $_ = xname 0 1 subname   $1 ->  a=5 b={3*a} ...
                $max++;          # increase unique identifier for this x-line
                $ref_prmval=0;
                @w = split(' '); # conversion of $_ ( xname 0 1 subname ) to array - delimiter is blanc by default
                $linestart = join(' ',@w[0 .. $#w-1]);  # ( xname 0 1 )

                $subnm = $w[$#w];      # subname is last Index
                $subnm = $subnm.$spf.$max; # subname_N

                $xnm = $w[0].$sublist; # xname is first index ( add $sublist if x-line is a call from inside a subckt )
                if($depth) {$subcall_sub{$xnm} = $subnm;}
                else {$subcall_root{$xnm} = $subnm;}


                $tmpline=$_; # memorize $_
                $ref_prmval=read_subckt_params($ref_prmval,$prmline); # get params and store it in %prmval
                $sub{$subnm} = $ref_prmval;   # unique params for this x-line saved here
                if($depth) {
                    push(@list,$linestart." ".$subnm);  # if x-line inside subckt -> add it to the actual subcktlist
                }
                last PRM_TST;
            }
            if (/^\.subckt\s+(\w+)/) {
                $ref_prmval=0;$ref_pprmval=0;$ref_funcprmval=0;$ref_pfuncprmval=0; # reset references
                $psubnm=$1; # .subckt subname 0 1 params: a1=2 b={2*a1} ...
                $depth++;  # augment deepthcounter till not .ends reached -> if depth > 0 all lines are recorded in $line
                $sublist .= $spf.$psubnm;   # sublist -> sublist + _subname for nested subckt
                if (s/params:(.*)//) {  # $_ is now ".subckt subname 0 1"  $1 = 1=2 b={2*a1} ...
                   $tmpline=$_;
                   $ref_prmval=read_subckt_params($ref_prmval,$1);
                   if ($hasprm) { # parametrized subcircuit in subcircuit not allowed
                       print "Line $linenum: ","Nested parameterized subckt definitions not permitted\n\n";
                   }
                   else {
                       $hasprm = 1; $start_nbr = $.; # remember starting linenumber of the .subckt-Line in the cirfile
                       $subprm{$psubnm} = $ref_prmval; # stores paramlist  - Var1=Val1 Var2=Val2 ........
                   }
                }
                push(@list, $tmpline);    # With parameter defs removed.     .subckt 1 2 subname
                last PRM_TST;
            }
            if (/^\.ends/) {   # if  .ends - Line found
                $sublist =~ s/($spf\w+)$//;  # sublist minus _N - one level higher , ""  if level 0
                if (--$depth == 0) {  # level-Subckthierarchycounter
                    if ($hasprm) {
                        $subckt{$psubnm} = join("\n",join(' ',$start_nbr,$.),@list,$_); # $. = linenbr of .ends in cirfile
                        $sub_lprm{$psubnm} = $ref_pprmval;
                        $sub_lfunc{$psubnm} = $ref_funcprmval;
                        $sub_lpfunc{$psubnm} = $ref_pfuncprmval;
                    }
                    $hasprm = 0;
                    undef @list; $sublist = '';  #    $list not longer used  -> free for new .subckt
                }
                last PRM_TST;
            }
            if ($depth) {          # if .subckt - Line found  - > deepth > 0 till not  .ends found
                                   # copy all devicelines in var @list, remove/store .param , .func , .pfunc lines before
                $tmpline=$_;
                if(s/^\.param//) {
                    $ref_pprmval = read_subckt_params($ref_pprmval,$_); # dont add this lines to @list
                }
                elsif(s/^\.func//)  {
                    $ref_funcprmval = read_subckt_funcline($ref_funcprmval,$_); # add this lines to @list
                    #push(@list, $tmpline);
                }
                elsif(s/^\.pfunc//) {
                    $ref_pfuncprmval = read_subckt_funcline($ref_pfuncprmval,$_); # dont add this lines to @list
                    #push(@list, $tmpline);
                }
                else {push(@list, $tmpline)};    # add this line to @list e.g. a deviceline like  "r1 1 0 1m"
                last PRM_TST;
            }
        }
    }
}
sub write_sub_table {
  local ($idx_n,$idx_m);
  my($key,$run,$ui_start,$val,$pattern);

  $idx_n=0;$idx_m=0;
  $ui_start=$max; # unique identifier start number
  foreach $val (values %subcall_root) {
     $idx_m=$idx_n; # synchronize
     &write_sub_table_entry($val,0);
     $run=1;
     while($run) {
         $pattern=$ui_subname[$idx_m];
         foreach $key (keys %subcall_sub) {
             if($key=~m/$spf$pattern$/) {write_sub_table_entry($subcall_sub{$key},1);}
         }
         if($idx_m<$idx_n-1) {$idx_m++;} else { $run=0;}
     }
  }
}
sub write_sub_table_entry {
  ($name,$caller)=@_;
  my ($nbr,$oldname);

  $oldname=$name; # oneinch_4
  $name=~s/(.*?)$spf(\d+)$/$1/;  # oneinch
  $nbr=$2; #4
  if($caller>0) {$nbr=++$max;} # if called from main $nbr is not changed , if not ->  $uistart++
  $ui_subname[$idx_n]=$name;
  $ui_number[$idx_n]=$nbr;
  $ui_xname[$idx_n]=$oldname;
  $ui_calleridx[$idx_n]= ($caller>0) ? ($idx_m): (-1);
  $idx_n++;
}
# Write the output file.
sub prm_wr {
  my (@w,@pnms,@list,@line);
  my($xnm,$subnm,$n,$i,$s,$nbr);
  local($sublist) = '';
  # unique_sub_table variables
  local @ui_subname=();
  local @ui_number=();
  local @ui_xname=();
  local @ui_calleridx=();

  &write_sub_table;
  %subcall = (%subcall_root,%subcall_sub);  # hash with all subcalls
  $depth=0; # subcircuit level deepth counter

PRMWR_SCAN: while ($_ = &prm_getline) {
      # write .control - .endc blocks
      if (/^\.control/i) {
          print OUTFILE "$_\n";
          while ($_ = &prm_getline) {
              prm_wrline($_);  # write everything between  .control and .endc unchanged to the OUTFILE
              next PRMWR_SCAN if (/^\.endc/i);
          }
      }
      tr/A-Z/a-z/;  # to lower case
      if (/^x/ && s/params:(.*)//) {   # (affects only xlines with params outside of subcircuits)
          @w = split(' '); $subnm = pop(@w);  #  store result of subst in array - split relates to $_
          $xnm = $w[0] . $sublist;
          prm_wrline(join(' ', @w, $subcall{$xnm}));  # write "xsubckt 1 2 subname_N"
          print OUTFILE "* $1\n";                     # subckt parameters as comment in next line  * { ..... }
          if (!defined($subprm{$subnm})) {
              print "Line $linenum: Subckt \"$subnm\" has no defined parameters\n\n";
              next PRMWR_SCAN;
          }
          next PRMWR_SCAN;
      }
      if (/^\.subckt\s+(\w+)/) {   # if .subckt found    $1 = subname 1 2 { ....  }
          if ($s = $subckt{$1}) {    # In $s is the whole subckt (from line)  (to line)  + startline,listing,endline   e.g.
              $s =~ /\d+\s+(\d+)/;   # $s = "8  13"
              $n = $1;
              &prm_getline until $. == $n;   # skip e.g.  Line 8 - 11 in the Inputfile ( this lines are yet recorded from first loop )
          }
          else {
              $depth++; $sublist .= $spf.$1;  # increase deepth
              prm_wrline($_);
          }
          next PRMWR_SCAN;
      }
      if (/^\.end\b/) { # end of cirfile detected , much work to do
         &uc_efghb_lines;
         &write_all_subckts;
         print OUTFILE ".end\n";
         last PRMWR_SCAN;
      }
      if (/^\.ends/) {            # .ends line found
          if (--$depth == 0)  { $sublist = ''; }    # depth --
          else                { $sublist =~ s/($spf\w+)$//; }
      }
      prm_wrline($_);     # all other lines  which are not .subckt ...  .ends, x-lines  copy 1:1 unchanged
  } # while getline of inputfile
}  # prm_write end
# search for v(node1,[node2]) or i(vname) expressions and uppercase it
# prevents for substitution with functionnames
sub uc_efghb_lines {
  my($key,$linenbr,@lines);

  foreach $key (keys %subckt) {
     @lines = split(/\n/,$subckt{$key});
     $linenbr=0;
     foreach (@lines) {
        if(/^[efghb]/) { #search for v(name) or i(vname) and replace with upper case letters V(NAME) I(VNAME)
          $lines[$linenbr]=~s/(\b[vi]\s*\([^\)]+\))/uc($1)/eg;
        }
        $linenbr++;
     }
     $subckt{$key} = join("\n",@lines); # write back
  }
}
sub write_all_subckts {
  my($idx_n,$nbr,$xname,$cidx,$cnbr,$csubname,$key,$ckey,$keymod,$val,$search);
  my(@cprm,@localprm,@line);
  my(%paramval,%newparam,%newfunc,%newpfunc);
  # while(@line) ....
  my(@splitline,$val,$key,@start,$nstart,$nline,$skip);
  my($oldxname,$oldsubname,$newxname);
  my($head,$tail,$expr,$copyline,$templine);

  # for all indexes of the sub_table
  $idx_n=0;
  foreach $subname (@ui_subname) {
       $nbr=$ui_number[$idx_n];
       $xname=$ui_xname[$idx_n];
       $cidx=$ui_calleridx[$idx_n];
       ############ xline and .subckt params ############
       *xprmval=$sub{$xname}; # get params from xline
       *subprmval=$subprm{$subname}; # get params from .subckt line
       # build sum of xline and .subckt params
       %paramval=%subprmval;
       foreach $key (keys %xprmval) {$paramval{$key}=$xprmval{$key};}
       # get the caller variablenames : params: .param .func .pfunc
       if($cidx>=0) {# if not called from root
         $cnbr=$ui_number[$cidx];
         $csubname = $ui_subname[$cidx];
         @cprm=();
         # params:
         *sub_lprms_al=$subprm{$csubname};
         @cprm = keys %sub_lprms_al;
         # .param
         if($sub_lprm{$csubname}) {
              *sub_lprm_al=$sub_lprm{$csubname};
              push(@cprm,keys %sub_lprm_al);
         }
         # .func
         if($sub_lfunc{$csubname}) {
              *sub_lfunc_al=$sub_lfunc{$csubname};
              push(@cprm,keys %sub_lfunc_al);
         }
         # .pfunc
         if($sub_lpfunc{$csubname}) {
              *sub_lpfunc_al=$sub_lpfunc{$csubname};
              push(@cprm,keys %sub_lpfunc_al);
         }
         # search all vals (RHS) of paramval for "caller" variables and append the caller uid to their names
         foreach $ckey (@cprm) {
            foreach $key (keys %paramval) {
               $val=$paramval{$key};
               $val=~s/\b$ckey\b/$ckey$spf$cnbr/g;
               $paramval{$key}=$val; # update
            }
         }
       #} from line 2889 to line 2903 changed
         ############ xline and .subckt params END ############
         # search for params: variablenames in RHS of params: append the subckt uid to their names
         foreach $key1 (keys %paramval) {
           foreach $key2 (keys %paramval) {
             $val = $paramval{$key2};
             if($val=~s/\b$key1\b/$key1$spf$nbr/g) {  # if something is replaced
                if($key1 eq $key2) { # recursion
                    print "PANIC:  variable recursion detected ->  varname: %paramval{$key1} value:$val";exit(1);
                }
                else {$paramval{$key}=$val;} # update
             }
           }
         }
       }
       # collect all variablenames of params: .param .func .pfunc in a hash (LHS)
       @localprm=();
       @localprm  = keys %{$sub_lprm{$subname}};
       push (@localprm,keys %{$sub_lfunc{$subname}});
       push (@localprm, keys %{$sub_lpfunc{$subname}});
       push (@localprm, keys %paramval);
       # search for the sumhash variablenames in .param .func .pfunc (RHS)
       # and append the subckt uid to their names (RHS)
       %newparam = %{$sub_lprm{$subname}};
       %newfunc = %{$sub_lfunc{$subname}};
       %newpfunc = %{$sub_lpfunc{$subname}};
       foreach $search (@localprm) {
          foreach $key (keys %newparam) {
               $val=$newparam{$key};
               $val=~s/\b$search\b/$search$spf$nbr/g;
               $newparam{$key}=$val;
          }
          foreach $key (keys %newfunc) {
               $val=$newfunc{$key};
               $val=~s/\b$search\b/$search$spf$nbr/g;
               $newfunc{$key}=$val;
          }
          foreach $key (keys %newpfunc) {
               $val=$newpfunc{$key};
               $val=~s/\b$search\b/$search$spf$nbr/g;
               $newpfunc{$key}=$val;
          }
       }
       ########### generate unique subckt #############
       # append subckt uid to all variablenames (key) in %paramval and
       # store all params: and .param variables to the global parmeter hash
       foreach $key (keys %paramval) {
           $keymod=$key.$spf.$nbr;
           #$param{$keymod}=$paramval{$key};
       }
       foreach $key (keys %newparam) {
           $keymod=$key.$spf.$nbr;
           #$param{$keymod}=$newparam{$key};
       }
       # get the subcktcode template from %subckt
       @line = split(/\n/,$subckt{$subname});
       shift(@line); # delete first entry with linenumberinfo from .. too
       #change .subckt NAME -> NAME_UID
       $line[0]=~s/$subname/$subname$spf$nbr/;
       prm_wrline("*");
       prm_wrline($line[0]);
        # add a comment line with caller name and perhaps params: .param line
       if($cidx>=0) { prm_wrline("* caller: $ui_subname[$cidx]$spf$ui_number[$cidx]"); }
       else { prm_wrline("* caller: root");}
       # append subckt uid to all variablenames (key) in %newfunc and %newpfunc
       # write this lines to the unique subcircuit
       prm_wrline("* params: converted to .param:");
       foreach $key (keys %paramval) {
           prm_wrline(".param $key$spf$nbr={$paramval{$key}}");
       }
       prm_wrline("* .param:");
       foreach $key (keys %newparam) {
           prm_wrline(".param $key$spf$nbr={$newparam{$key}}");
       }
       foreach $key (keys %newfunc) {
           prm_wrline(".func $key$spf$nbr$newfunc{$key}");
       }
       foreach $key (keys %newpfunc) {
           prm_wrline(".pfunc $key$spf$nbr$newpfunc{$key}");
       }
       # write the other subcircuit lines to OUTPUT
       foreach (@line) {
           @splitline=split;
           $skip = &skipnumber($splitline[0]);
           if($splitline[0] eq ".subckt") {  # for nested .subckt's
                prm_wrline($_[0]);next;
           }
           @start=splice(@splitline,0,$skip); # @start = "R1 1 0 "  @line=rest
           $nstart=join " ",@start;
           $nline=join " ",@splitline;
           # if x-line change the x-name to the uid-xnames
           if($nstart=~m/(^x\w+)/i) { # for x-calls with params inside subcircuits -> change the unique id
                #$nline=$nstart.$nline; # now the whole line again ( we don't know the count of ports )
                $nline=~m/((\w+)$spf\d+)$/i; # search starting from the end
                $oldxname=$1; # lump_7
                $oldsubname=$2; # lump
                if(defined($oldsubname)) { # if not _123.. -> x-line without parameter !!!
                    $newxname=new_uid($idx_n,$oldxname,$oldsubname);
                    if($newxname) {
                        $nline=~s/$oldxname$/$newxname/;
                    }
                }
                $nline=$nstart." ".$nline; # compose back
           }
           else { # no x-line
             # search for the sumhash variablenames in the actual line and append the subckt uid to their names
             foreach (@localprm) { # sum of variablenames from ->  params: .param .func .pfunc
                 $search=$_;
                 if($nstart=~m/^[befgh]/) { # b-efgh-line
                     $nline=~s/\b$search\b/$search$spf$nbr/g; # exact search and replace
                 }
                 else { # all other lines , devicelines,  .modellines , analysislines ......
                        # be more specific  -> only search in {expr}
                     $copyline="";
                     $templine=$nline;
                     while ($templine=~m/([^\{]*)\{([^\}]*)\}(.*)/) {
              	      # parameterexpr with { $expr } present in deviceline
                        $head=$1; $tail=$3;$expr=$2;
                	$expr=~s/\b$search\b/$search$spf$nbr/g;
                	$copyline .= $head."{".$expr."}"; # reconstruct it with sourrounding paranthesis {}
                        $templine=$tail; # perhaps another param in line ?
                     }
                     $nline=$copyline.$templine;
                 }
             }
             $nline=$nstart." ".$nline; # write back
           }
           prm_wrline($nline);     # write with parameter =  parameter#k substituted line to outfile
       }
       prm_wrline(" ");
       $idx_n++; # generate next unique subcircuit
    }
}
sub new_uid {
   my ($aktidx,$xname,$subname)=@_;
   my ($ui,$i,$c,$k);

   # search starts from $aktidx -> with ui_calleridx[$i] has the same value
   $k=$i=$aktidx;
   while(($c=$ui_calleridx[$i])!=$aktidx) {
       $i++;
       if($i>=@ui_calleridx) {return(-1)}; # no index found -> perhaps subcircuit with _123 but no params
   }
   $ui="Error -> no uid found for this x-line !!";
   while ($c==$k)  {
        if($ui_xname[$i] eq $xname) {$ui=$subname.$spf.$ui_number[$i];last;}
        else
        { $i++;$c=$ui_calleridx[$i];}
   }
   return $ui;
}
# Translate a possible unit into a multiplier factor.
# Parameter is the unit letter string assumed lower case.
sub unit2mult {
    my($u) = shift;
    $u = ($u =~ /^(mil|meg)/ ? $1 : substr($u, 0, 1));
    $u = defined($units{$u}) ? $units{$u} : 1;
}
# Write an output file line with a max length.  The line is split on
#   whitespace or '=' at a point less than or equal to the max length
#   and output as a spice continuation line.
#   If a splitting delimiter is not found within $MAXLEN, then allowable
#   length is increased, potentially up to the actual line length.
#   NOTE: outputs '\n'.
#   $MAXLEN sets the max value, $DMAXLEN the increment.
#   File handle = OUTFILE.
sub prm_wrline {
  my($line) = shift;
  my($max, $s, $m);
  $max = $MAXLEN;
  until ($line eq '') {
     if (length($line) > $max) {
        $m = substr($line, 0, $max);
        if ($m=~/((\s|\=)[^(\s|\=)]*)$/) {  # seperate on     =    or    Blank
            $s = $` . $2;
            $line = '+' . substr($line, length($s));    # seperate with spice +
        }
        else { $max += $DMAXLEN; next; }
     }
     else { $s = $line; $line = ''; }
     print OUTFILE "$s\n";    #  write line to outfile
     $max = $MAXLEN;
  }
}
# reads subckt params to a hash and returns a ref to this hash : param1->val1 param2->val2 .....
sub read_subckt_params {
  my ($line,$done,$i,$j,$temp1,$temp2);
  $hashptr=$_[0];
  $line=$_[1];  #  e.g. a=3 b={2*a+5.0}
  $_=$line;

  if(!($hashptr)) {$hashptr={};} # generates new anonymous hash if first call ($hashptr=0)
  *hash=$hashptr; # alias for $hashptr to facilitate access to anonymous hash

  $done=0;
  until ($done) {
    if (/^\s*(\S+)\s*\=\s*\{([^\}]*)\}(.*)/) { # search for var={ }
      # $1 = Variable  $2 = { .... } without paranthesis  $3 = Rest
      $_=$2;
      $temp1 = $1;
      $temp2 = $3;
      # s/([\(\)\*\+\-\/])/ $1 /g; # space delimit operators
      $hash{$temp1}=$_;   # stores param to hash
      $_=$temp2;  # perhaps another param present ?
    }
    elsif (/^\s*(\S+)\s*\=\s*(\S+)(.*)/) { # search for Var=value
       #  $1 = varname  $2 = num. value  $3 is the possible remainder
       $hash{$1} = &unit($2);
        $_=$3;  # perhaps another param present  ?
    }
    else   { $done=1; }
  } # done
  return $hashptr;
}
# reads .func or .pfunc line to a hash and returns a ref to this hash : funcname(a,b) (2*a+b)
sub read_subckt_funcline {
  my ($line,$i,$j,$fname,$parm,$ex);
  $hashptr=$_[0];
  $line=$_[1];  #  e.g. pythag(a,b) (a*a+b*b)
  $_=$line;

  if(!($hashptr)) {$hashptr={};} # generates new anonymous hash if first call ($hashptr=0)
  *hash=$hashptr; # alias for $hashptr to facilitate access to anonymous hash

  m/\s+([^\(]+)(\([^\)]+\))\s+(.*)/i; #  $1=fname, $2=parameter , $3=expr
      # how many params in $2 ? .func neg(x) ((x)*(x)) -> $1=neg $2=x $3=((x)*(x))
  $fname=$1;
  $parm=$2;
  $ex=$3;
  $fname=~s/\s+//g; # delete blanks
  $parm=~s/\s+//g; # delete blanks
  $ex=~s/\s+//g; # delete blanks
  $hash{$1}=$2." ".$3;
  return $hashptr;
}
sub expand_incs {
  my ($i,$file,$cnt,@inc);

  for ($i=1;$i<@deck;$i++) {
    $_=$deck[$i];
    @inc=();
    if ( /^\.inc\s+(.*)/ ||  /^\.include\s+(.*)/  )  { #   another inc to search for
      $file=$1;
      $file=~s/[\'\"]//g;
      @inc=&read_includefile($file); # include this
      if(@inc) {
         splice(@deck,$i,1,@inc); # put tmpdeck in deck starting (and deleting) with .inc line
         # if another .inc line in this file manage this
      }
    }
  }
}
sub read_includefile {
  my ($file,$model,$found,@inc );
  $file=$_[0];
  @inc=();
  open (INCLUDE, "$file") || die "include file $file cannot be opened";
  $found=0;
  while (<INCLUDE>) {
      chop;
      # dont lowercase stuff in quotes
      if (/(.*)([\'\"])(.*)([\"\'])(.*)/) {
        $_=lc($1) . $2 . $3 . $4 . lc($5);
      }
      else { $_ = lc($_); }
      s/^\*\$//; # *$ should be interpreted as a nutmeg commandline -> remove *$ to enable it
      s/\;.*//; # no inline comments with ;
      s/^\*.*//;  # no comments starting with *
      s/\s\s+/ /g; # shrink multiple whitespaces
      s/^\s*//; # trim leading whitespaces and delete blanc lines
      # s/([^\s\=]+)\s*=\s*([^\s\=]+)/$1=$2/g; # compress around =
      if (/^\s*\+(.*)/) { # continuation
          $_ = pop (@inc) . " " . $1;
      }
      push @inc,$_ if (length($_)>0);
  }
  close(INCLUDE);
  return @inc;
}
#returns global parameters and funclines of libfile
#search this lib for models defined in %xmodels or %devicemodels
#if found returns all ".subckt modelname ... .. .ends"  or ".model modelname ... "  lines
sub read_libfile {
   my ($i,$file,$modelnm,@lib,@add,$found,$go);

   $file=$_[0];
   @lib=(); # place for whole libfile
   @add=(); # place for all .model and .subcktlines
   # source in libfile
   open (LIB, "$file") || die "libfile $file cannot be opened";
   while (<LIB>) {
      chop;
      # dont lowercase stuff in quotes
      if (/(.*)([\'\"])(.*)([\"\'])(.*)/) {
        $_=lc($1) . $2 . $3 . $4 . lc($5);
      }
      else { $_ = lc($_); }
      #s/^\*\$//; # *$ should be interpreted as a nutmeg commandline -> remove *$ to enable it
      s/\;.*//; # no inline comments with ;
      s/^\*.*//;  # no comments starting with *
      s/\s\s+/ /g; # shrink multiple whitespaces
      s/^\s*//; # trim leading whitespaces and delete blanc lines
      # s/([^\s\=]+)\s*=\s*([^\s\=]+)/$1=$2/g; # compress around =
      if (/^\s*\+(.*)/) { # continuation
          $_ = pop (@lib) . " " . $1;
      }
      push @lib,$_ if (length($_)>0);
   }
   close(LIB);
   #collect all global .param .func .pfunc statements of the libfile and store it to @add
   #collect all global .lib statements and store it to %libfiles
   $go=1;
   for ($i=0;$i<@lib;$i++) {
      $_=$lib[$i];
      if(/^\.subckt/) {$go=0;}
      if(/^\.ends/) {$go=1;}
      if($go) {
         if(/^\.param/i) {
            push @add,$_ ;
         }
         elsif(/^\.func/i) {
            push @add,$_ ;
         }
         elsif(/^\.pfunc/i) {
            push @add,$_ ;
         }
         elsif(/^\.lib\s+(.*)/i) { # global .lib outside of .subckt's
            $file=$1;
            $file=~s/[\'\"]//g; # libfilename without quotes
            if(!defined($libfiles{$file})) {
               $libfiles{$file}=1;$flag=1;
               # indicates that a NEW global .lib is found -> don't give up before this lib is searched for
               # unresolved models
            }
         }
      }
   }
   #search @lib for all .model lines defined in %devicemodels , if found remove it from %devicemodels
   #search @lib for all .subckt lines defined in %xmodels , if found remove it from %xmodels
   #store all modellines found so far to @add
   for ($i=0;$i<@lib;$i++) {
      $_=$lib[$i];
      if (/^\.model/i) {
        foreach $modelnm (keys(%devicemodels)) {  #for all models in hash
          if (/^\.model\s+$modelnm\b/i) {
             push (@add,$_); # put it all together in tmpdeck
             while($lib[$i+1]=~m/^\+/) { # if continuation lines
                push(@add,$lib[$i]); #  add it
                $i++;
             }
             delete($devicemodels{$modelnm});$flag=1;
             if((!%devicemodels) && (!%xmodels)) {return(@add);} # we are done before end of lib reached
          }
        }
      }
      if(/^\.subckt/i) {
         $found=0;
         foreach $modelnm (keys(%xmodels)) {  #for all models in hash
            if (/^\.subckt\s+$modelnm\b/i) {$found=1;delete($xmodels{$modelnm});}
            while($found) { # not .ends
               if(/^\.ends/i) {
                  push (@add,$_); # .ends
                  $found=0;$flag=1;
                  if((!%devicemodels) && (!%xmodels)) {return(@add);} # we are done before end of lib reached
               }
               else {
                  push (@add,$_); # put it all together from .subckt till .ends in @add
                  $i++;$_=$lib[$i];
               }
           }
        }
      }
   }
   return(@add);
}

sub store_modellines {
  my $mod;
# store all xmodels in hash %xmodels
  for ($i=0;$i<@tmp;$i++) {
    $_=$tmp[$i];
    if ( /^x/ ) { # search for modelnames in x-lines
      if( /(\w+)\s+params:/i )   {$mod=$1;} # xname params: pm1=val1 ....
      elsif( /(\w+)\s+\S+\s*\=/ ) { # parameters present but no params: keyword
          #insert params: keyword in between
          s/(\w+)(\s+\S+\s*\=)/$1 params:$2/;
          $mod=$1;
          $tmp[$i]=$_; # write back
      }
      else { # no parameters -> xname must be last name in line
          m/(\w+)\s*$/i;
          $mod=$1;
      }
      if(!defined($xmodels{$mod})) {
          $xmodels{$mod}=1;$flag=1;
      }
    }
  }
}

sub store_devicemodellines {
my($i,$control,$mod,$n,@line);
  # store all devicemodels in hash %devicemodels
  $control=0;
  for ($i=0;$i<@tmp;$i++) {
    if ($tmp[$i]=~m/^\.control/i) {$control=1;}
    if ($tmp[$i]=~m/^\.endc/i) {$control=0;}
    if (!$control) {
      $_=substr($tmp[$i],0,1);
      $n=tr/cdjmoqrsuw/2234432433/; # these devices can have models
      if($n) {
        $n=$_;$_=$tmp[$i];
        @line=split;
        $mod=$line[$n+1];
        if(isnumber($mod) || isexpression($mod)) {next;}
        if($mod=~/^\s*(q=|flux=|value|poly)/i) {next;}
        if(!defined($devicemodels{$mod})) {
            $devicemodels{$mod}=1;$flag=1;
        }
      }
    }
  }
}
sub remove_modellines {
  my $i;
  # now search .subckt and .model lines and delete models from hash
  for ($i=0;$i<@tmp;$i++) {
    $_=$tmp[$i];
    if(/^.subckt\s+(\w+)/) {  #search for .subckt lines in actual file if found delete model from $xmodels
       if(defined($xmodels{$1})) {
          delete($xmodels{$1});$flag=1;
       }
    }
    if(/^.model\s+(\w+)/) { #search for .model lines in actual file if found delete model from $devicemodels
      if(defined($devicemodels{$1})) {
         delete($devicemodels{$1});$flag=1;
      }
    }
  }
}
sub store_lib {
  my ($i,$file);

  for($i=0;$i<@tmp;$i++) {
    if ($tmp[$i]=~m/^\.lib\s+(.*)/) { #   another library to search for ( one or more or all ) models
       $file=$1;
       $file=~s/[\'\"]//g; # libfilename without quotes
       if(!defined($libfiles{$file}))
       { $flag=1;$libfile{$file}=1; }
       splice(@tmp,$i,1);$i--; # delete line
    }
  }
}
# search all x lines and stores modelnames to %xmodels
# search all m,r,c,s,w,o,u,d,q,j-devicelines and stores modelnames ( if present ) to %devicemodels
# search for .subckt lines and delete these already defined modelnames from %xmodels
# search for .model lines and delete these already defined modelnames form %devicemodels
# search for .lib lines , delete it and add modellines needed (%xmodels,%devicemodels) from the external .lib-files
sub expand_libs {
  my ($i,$file,$flidx,$cnt);
  local (@addlib,%libfiles,@tmp,%xmodels,%devicemodels,$flag);

  $lidx=1;
  for ($i=1;$i<@deck;$i++) { #  while .lib lines present
    $_=$deck[$i];
    if (/^\.lib\s+(.*)/) { #   another library to search for ( one or more or all ) models
          $lidx=$i;
          $file=$1;
          $file=~s/[\'\"]//g; # libfilename without quotes
          $libfiles{$file}=1;
          splice(@deck,$i,1);$i--; # delete line
    }
  }
  @tmp=@deck;
  @addlib=();
  &store_modellines(@tmp); # search tmp for x-subckt-calls and store to hash
  &store_devicemodellines(@tmp); # search tmp for devicelines with models and store to hash
  &remove_modellines(@tmp); # search tmp for already defined .subcktlines and .modellines and remove from hash

  if(!(%xmodels) && !(%devicemodels)) { # are we done now
      return; # no models to search for !!!!!!
  }

  while(!0) {
     $flag=0;
     foreach $libfile (keys %libfiles) { #  all libfiles found so far
        @tmp=&read_libfile($libfile); # search the lib for models defined in %xmodels or %devicemodels
                                        # if found delete it from x- and device - models hash and add code to @tmp
                                        # search this lib for additional global .lib lines -> store it to %libfiles
                                        # and set flag to 1
                                        # search this lib for global .param .func .pfunc lines and add code to @tmp
        &store_modellines; # search @tmp for new x-subckt-calls , if found store it to hash
        &store_devicemodellines; # search @tmp for new devicelines with models , if found store it to hash
        &remove_modellines; # search @tmp for already defined .subcktlines and .modellines and remove them from hash
        &store_lib;    # search @tmp for new local .lib lines and add it to %libfiles
        if(@tmp) {push(@addlib,@tmp);}
        if(!(%xmodels) && !(%devicemodels)) { # are we done now
           splice(@deck,$lidx,0,@addlib); # we are done -> put addmodels in deck
           return; # normal return
        }
     }
     if(!$flag) {&debug_models;} # if no more change and no normal return -> must be error
  }
}


sub debug_models {
   my $modelnm;
   foreach $modelnm (keys(%xmodels))  #for all models in hash
      { print "\nsubcktmodelname not defined : $modelnm\n"; }
   foreach $modelnm (keys(%devicemodels))  #for all models in hash
      { print "\ndevicemodelname not defined : $modelnm\n";  }
   exit(1);
}

sub loadbias {
  my ($i,$found,$filename);

  $found=0;
  for ($i=1;$i<@deck;$i++) {
    $_=$deck[$i];
    if(/^.loadbias\s+(.*)/) { #search for .loadbias filename
       $filename=$1;
       $found=1;
       last;
    }
  }
  if($found) {
     splice(@deck,$i,1,".include $filename"); # add includeline .include filename to deck !!!
  }
}
#.savebias options infile outfile
# options:  -tran -timepoint=val (val=nr of the timepoint in the rawfile)
# this can easily be changed to the timevalue -> see documentation at the sourcecode
sub savebias {
  my ($i,$j,$found,$timevar,$infile,$outfile,$cnt,@rest,$part,$analysis);
  my ($vargo,$valgo,$varcnt,$valcnt,$dc,$tran,$first,@vars,@vals,@line);
  $dc=0;
  $tran=0;
  $found=0;
  $timevar=0;
  # cirfile = $infile
  for ($i=1;$i<@deck;$i++) {
    $_=$deck[$i];
    if(/^.savebias\s+(.*)/) {
       $found=1;
       $cnt=@rest=split('\s+',$1);
       for ($j=0;$j<$cnt;$j++) {   # default is "op"
          if($rest[$j] eq "-tran") {$tran=1;}
          elsif ($rest[$j]=~m/-timepoint=(.*)/) { $timevar=$1;next;}
          else { # must be filename
             $infile=$rest[$j];
             $outfile=$rest[$j+1];
             last;
          }
       }
       $deck[$i]="*".$deck[$i];
       last;
    }
  }
  $vargo=0;$valgo=0;$varcnt=0;$valcnt=0;$first=0;
  $points=1; # default is op
  if($found) {
     open (INFILE, "$infile") || die "include file $infile cannot be opened";
     while (<INFILE>) {
        if(m/^values:/i) {
 	    $vargo=0;$valgo=1; # now the values are managed
 	}
 	elsif(m/^variables:/i) {$vargo=1;} # first the variables
        elsif($valgo) {
 	   if($timevar>0) { # we have to search for the right timepoint
              if((@line=split())>1) { # new timepoint has two entries
                 if($line[0]>=$timevar) {$timevar=0;} #  AS TIMEPOINT (Integer)
                 else {next;}
 	      }
 	      else {next;}
 	   }
 	   if($first) {$first=0;next;}
 	   else { # now the values
              $valcnt++;
 	      if($valcnt>$varcnt) {last;}  # leave while loop !!!!!!!!!!!!!!!
 	      if((@line=split())>1) {push(@vals,$line[1]);} # new timepoint has two entries
 	      else {push(@vals,$line[0]);}
 	   }
 	}
 	elsif($vargo) {
           @line=split; # $_
 	   if($line[1] eq 'time') {$first=1;next;}
           else { # should be op and normal var
              if($line[2] eq 'voltage') { # this is a .nodeset candidate
                 push(@vars,$line[1]);
 	         $varcnt++;
 	      }
 	      else {last;} # we are done now -> no more voltages
 	   }
 	}
 	elsif(m/points:\s+(.*)/i) {$points=$1;}
 	elsif(m/binary/i) {return;} # giving up -> no outfile is written
     }
     close(INFILE);

     open (OUTFILE, "+>$outfile") || die "bias file $outfile cannot be generated";
     print OUTFILE "* SAVEBIAS from $infile :\n ";
     print OUTFILE ".nodeset ";
     for($i=1;$i<$varcnt+1;$i++) {
         if(($i%5)==0) {print OUTFILE "\n+ ";} # max 5 values per line -> if more add +
         print OUTFILE "$vars[$i-1]"."="."$vals[$i-1] ";
     }
     print OUTFILE "\n";
     close(OUTFILE);
  }
}
sub pwl_file {
my ($i,$filename,$varname);
  ###########################################################################
  # fileformat: generated with nutmeg : print col v(1) v(2) v(3) > outfile
  ###########################################################################
  #                     ** third order elliptic active filter **
  #                    Transient Analysis  Mon Aug 21 22:48:43  2006
  #--------------------------------------------------------------------------
  #Index   time            v(1)            v(2)            v(3)
  #--------------------------------------------------------------------------
  #0	 0.000000e+00	-5.000000e-01	 2.003981e-03	 1.399462e-01
  #1	 1.000000e-06	-5.000000e-01	 2.003981e-03	 1.399462e-01
  #2	 2.000000e-06	-5.000000e-01	 2.003981e-03	 1.399462e-01
  ############################################################################
  for ($i=1;$i<@deck;$i++) {
    $_=$deck[$i];
    if(/^[vi].*?pwl.*?\bfile=\s*'(.*?)'\s+var=\s*'(.*?)'/) { #v or i ... pwl ... file=filename...var=varname
       $filename=$1;
       $varname=$2;
       &add_pwl_line($filename,$varname,$i);
    }
  }
}

sub add_pwl_line {
   my($filename,$varname,$i)=@_;
   my($j,$k,$col,@cols,$idx,$found,@pwldata,$pwlline);

   $found=0;
   open (PWLDATA, "$filename") || die "Error on pwlline at $i : filenamme $filename cannot be opened";

   @pwldata=<PWLDATA>;
   $varname=quotemeta($varname);
   for ($j=0;$j<@pwldata;$j++) {
     $_=$pwldata[$j];
     if(m/\b$varname/) {
           $found=$j;
    	   last;
     }
   }
   if($found) {
      $deck[$i]=~s/\bfile\=.*//; # delete from file= to end
      $pwlline=$deck[$i];
      # v1 1 0 pwl 0s 0v 1s 1v
      @cols=split(/\s+/,$pwldata[$found]);
      $idx=0;
      $k=0;
      foreach $col (@cols) {
         if($col=~m/$varname/) {last;}
         else {$idx++};
      }
      for($j=0;$j<@pwldata-$found-1;$j++) {
         if($pwldata[$j+$found+1]=~m/^index/i) {$k++;next;} # no varnames line
         if($pwldata[$j+$found+1]=~m/^\s+/) {$k++;next;}    # no blanc line
         if($pwldata[$j+$found+1]=~m/^[-_]/) {$k++;next;}   # no -------- line
         @cols=split(/\s+/,$pwldata[$j+$found+1]); # start at next line after the varname-line
         $pwlline.=" ($cols[1]s $cols[$idx]v) "; # add time var pair to pwlline
      }
      splice(@deck,$i,1,$pwlline);
   }
   else { die "Error on pwlline at $i : varname $var not found"; }
   close(PWLDATA);
}
sub pp_{
    my $tmp;
    my $filename_path; # windows specific , uncomment in unix
    my $filename_wo_path;

    $filename_path=$_[1];
    $filename_wo_path=$filename_path;
    $filename_path =~ s/([^\\])*$//; # windows specific use in unix s/([^\/])*$//;
    $tmp=$filename_path;
    $filename_path = quotemeta($filename_path); # windows specific , uncomment in unix
    if($filename_path)
    { $filename_wo_path =~ s/$filename_path//};
    return($tmp.$_[0]."_".$filename_wo_path);
}
sub output_debug {
  my($i,$name,$value);

   print "* DEBUG of deck: $deck[0]\n";
   $deck[0]=~ s/(^[^\*].*)/*$1/; # if not asterisk as first character - insert it
   print "\n* ouput of all parameters";
   print "\n* =======================\n\n";
   foreach $name (sort keys %param) {
        print "* $name: $param{$name}\n";
   }
   print "\n* ouput of all functions";
   print "\n* ======================\n\n";
   for($i=0;$i<=$memidx;$i++) {
        print "* $funcname[$i] -> $expr[$i]  $anz_pm[$i] parameter\n";
   }
   print "\n* ouput of all pfunctions";
   print "\n* =======================\n\n";
   for($i=0;$i<=$memidx2;$i++) {
        print "* $pfuncname[$i] -> $pexpr[$i]  $panz_pm[$i] parameter\n";
   }
   print "\n";
}
sub do_ltspice {
    my($addpm,$i,@kill,@addctrl);

    $addpm = ".param tripv=1 tript=1";
    splice(@deck,1,0,$addpm);   # insert new line for tripv and tript parameter
    #value or bsrc  + tripdv={tripv} tripdt={tript}
    for ($i=0;$i<@deck;$i++) {   # for the whole deck
       $_=$deck[$i];
       if ( s/value\s*\=\s*/v=/i ) # subs value= with v=
       { $deck[$i]=$deck[$i]." tripdv={tripv} tripdt={tript}"; } #
       if( substr($_,0,1) eq "b" )  { # b-source like
          $deck[$i]=$deck[$i]." tripdv={tripv} tripdt={tript}";
	  $deck[$i]=~ s/e\^/exp/g; # e^() to exp()
          $deck[$i]=~ s/\^/\*\*/g; # raise to power in ltspice is ** instead of ^ standardspice
       }
    }
    #################################################
    # .control till .endc  lines -> delete
    # add . before tran,dc,op,ac....lines and store it
    #################################################
    @addctrl=();
    @kill=();
    for ($i=1;$i<@deck;$i++) {   # for the whole deck
       $_=$deck[$i];
       if ( s/^tran\b/\.tran/ ) {push @addctrl,$_;}
       if ( s/^ac\b/\.ac/ ) {push @addctrl,$_;}
       if ( s/^dc\b/\.dc/ ) {push @addctrl,$_;}
       if ( s/^options\b/\.options/ ) {push @addctrl,$_;}
       if ( s/^op\b/\.op/ ) {push @addctrl,$_;}
       #delete from .control till .endc
       if( m/^\.control/i ) {$ctrl_found=1;}
       if( m/^\.endc/i ) {$ctrl_found=0;push @kill,$i;}
       if($ctrl_found) {push @kill,$i;}
    }
    &zapdeck(@kill);
    @probe=@addctrl; # is added by printdeck
    &printdeck; # prints to outfile
    # other things are better managed by ltspice itself
    exit(0);
}
sub getargs {
  my($arg);

  while(@ARGV) { # handles all command line switches
    $arg=shift @ARGV;
    last if substr($arg,0,1) ne '-'; # no option if not started with -
    $spice3=1 if $arg eq '-sp3';
    $ltspice=1 if $arg eq '-ltspice';
    $tinylines=0 if $arg eq '-notinylines';
    $check=1 if $arg eq '-check';
    $xornot=1 if $arg eq '-xornot';
    $debug=1 if $arg eq '-debug';
    $tosub=1 if $arg eq '-tosub';
    $tolib=1 if $arg eq '-tolib';
    $fromsub=1 if $arg eq '-fromsub';
    $fromlib=1 if $arg eq '-fromlib';
    # insert other options if necessary
    if ($arg eq '-v' || $arg eq '--version')
    {  print "ps2sp version 4.14\n".
	   "Copyright (C) 2003/2004/2005/2006/2007 Friedrich Schmidt <frie.schmidt\@aon.at>\n\n".
	   "This is free software; see the source for copying conditions.  There is NO\n".
	   "warranty; not even for MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.\n";
       exit;
   }

    if ($arg eq '-h' || $arg eq '--help')
    {  print "Usage: perl ps2sp.pl [OPTION] infile > outfile\n\n".
	   "  -h, --help     displays the help screen\n".
	   "  -v, --version  display version information and exit\n".
	   "  -sp3           switch means conversion of pspice table to spice 3 b-source\n".
	   "                 instead of xspice core model ( default )\n".
	   "  -ltspice       switch means conversion of ^ spice 3 power to ** ltspice\n".
	   "                 power and addition of tripdv=1 tripdt=1 in b-lines\n".
	   "  -debug         for debugging all .param .func and .pfunc definitions\n".
	   "                 ( default is nodebug )\n".
	   "  -tosub         only output subckt expansions\n".
	   "  -fromsub       inputfile is a sub.tmp file\n".
	   "  -tolib         only output lib expansions\n".
	   "  -fromlib       inputfile is a lib.tmp file\n".
	   "  -check         determine the same count of open and closed paranthesis\n".
	   "                 in b-lines ( default is nocheck )\n".
	   "  -notinylines   produces longer b-lines for some functions ( default is\n".
	   "                 tinylines = shorter b-lines )\n".
	   "  -xornot        allows ^ and ~ operators in the netfile (don't mix with ^ as\n".
	   "                 power operator) use the ** operator as power instead\n".
	   "\nReport bugs to Friedrich Schmidt <frie.schmidt\@aon.at>\n";
       exit; }
  }
  # this arg must be a filename since no "-" before the name
  unshift @ARGV,$arg; # back to the roots
}

sub quotes { # c:\xx\filename -> "c:\xx\filename"
    return("'$_[0]'");
}

sub initialize_predefined_parameter_functions {
  # predefined global Parameter
  $param{"pi"}="3.1415926535898";
  $param{"echarge"}="1.602190e-019";
  $param{"kelvin"}="-2.73150e+002";
  $param{"planck"}="6.626200e-034";
  $param{"temp"}=$tnom;
  # ............. add user defined parameter here !!!!

  # predefined global nodes
  $globals{'times'}=1; # global node

  # predefined functions
  $fidx=0; # startindex of user defined .func lines
  # .func definitions are used for b-sources ( syntax:  must always be spice syntax )
  # whereas .pfunc definitions are used for all other lines
  # for compatibility to pspice all .func definitions are copied to .pfunc equivalents
  # and can therefore be also used for other than b-lines ( all other devicelines and .param , .model , .tran .... )
  # parameter placeholders used are   __1 , __2 , __3  .....
  $funcname[0]="pwrs";
  $anz_pm[0]=2;
  $expr[0]="sgn(__1)*abs(__1)^(__2)";
  $fidx=1;
  # 5.9.2006 added *(abs(sgn(__1))) -> compatibility to nutmeg
  $funcname[1]="pos";
  $anz_pm[1]=1;
  $expr[1]="(u(__1)*(abs(sgn(__1))))";
  $fidx=2;
  $funcname[2]="neg";
  $anz_pm[2]=1;
  $expr[2]="(pos(-(__1)))";
  $fidx=3;
  $funcname[3]="if";
  $anz_pm[3]=3;
  $expr[3]="(u((__1)-0.5)*(__2)+u(0.5-(__1))*(__3))";
  $fidx=4;
  $funcname[4]="pwr";
  $anz_pm[4]=2;
  $expr[4]="(abs(__1)^(__2))";
  $fidx=5;
  $funcname[5]="pow";
  $anz_pm[5]=2;
  if($ltspice) {
     $expr[5]="((__1)**(__2))";
  }
  else # spice3/xspice
  {
     $expr[5]="((__1)^(__2))";
  }
  $fidx=6;
  # only binary parameter !!
  $funcname[6]="not";
  $anz_pm[6]=1;
  $expr[6]="1-(abs(sgn(__1)))";

  $fidx=7;
  $funcname[7]="eq";
  $anz_pm[7]=2;
  $expr[7]="(not((__1)-(__2)))";
  $fidx=8;
  # or (1-eq((__1),(__2)))
  $funcname[8]="ne";
  $anz_pm[8]=2;
  $expr[8]="(abs(sgn((__1)-(__2))))";
  $fidx=9;
  $funcname[9]="gt";
  $anz_pm[9]=2;
  $expr[9]="(u((__1)-(__2))*(abs(sgn((__1)-(__2)))))";
  $fidx=10;
  $funcname[10]="lt";
  $anz_pm[10]=2;
  $expr[10]="(u((__2)-(__1))*(abs(sgn((__2)-(__1)))))";
  $fidx=11;
  $funcname[11]="ge";
  $anz_pm[11]=2;
  $expr[11]="(gt((__1),(__2))+(eq((__1),(__2))))";
  $fidx=12;
  # 1-pos(x-y)
  $funcname[12]="le";
  $anz_pm[12]=2;
  $expr[12]="(lt((__1),(__2))+(eq((__1),(__2))))";
  $fidx=13;
  $funcname[13]="max";
  $anz_pm[13]=2;
  #$expr[13]="(gt((__1),(__2))*(__1)+le((__1),(__2))*(__2))";
  $expr[13]="((__1)*u((__1)-(__2))+(__2)*u((__2)-(__1)))";
  $fidx=14;
  $funcname[14]="min";
  $anz_pm[14]=2;
  $expr[14]="((__2)*u((__1)-(__2))+(__1)*u((__2)-(__1)))";
  $fidx=15;
  $funcname[15]="limit";
  $anz_pm[15]=3;
  #$expr[15]="((__1)+gt((__1),(__3))*((__3)-(__1))+lt((__1),(__2))*((__2)-(__1)))";
  #$expr[15]="(max(min((__1),(__3)),(__2)))";
  # u(x-hi)*hi + u(hi-x)*u(x-lo)*x + u(lo-x)*lo
  $expr[15]="((u((__1)-(__3))*(__3))+(u((__3)-(__1))*u((__1)-(__2))*(__1))+(u((__2)-(__1))*(__2)))";
  #equal LIMIT(x,lolim,uplim) = MAX(MIN(x,uplim),lowlim)
  $fidx=16;
  $funcname[16]="and";
  $anz_pm[16]=2;
  $expr[16]="(sgn(__1)*sgn(__2))";
  $fidx=17;
  $funcname[17]="or";
  $anz_pm[17]=2;
  $expr[17]="(sgn((__1)+(__2)))";
  $fidx=18;
  $funcname[18]="xor";
  $anz_pm[18]=2;
  $expr[18]="(abs(sgn((__1)-(__2))))";
  $fidx=19;
  $funcname[19]="stp"; # new
  $anz_pm[19]=1;
  $expr[19]="(u(__1))";
  $fidx=20;
  $funcname[20]="exp"; # new
  $anz_pm[20]=1;
  $expr[20]="(e^(__1))";
  $fidx=21; #
  $funcname[21]="buf"; #
  $anz_pm[21]=1;
  $expr[21]="(pos((__1)-0.5))";
  $fidx=22;
  $funcname[22]="inv";
  $anz_pm[22]=1;
  $expr[22]="(1-(pos((__1)-0.5)))";
  $fidx=23;
  $funcname[23]="atan2";
  $anz_pm[23]=2;
  $expr[23]="((sgn(__2)+1-abs(sgn(__2)))*acos((__1)/sqrt((__1)*(__1)+(__2)*(__2))))";
  $fidx=24;
  # ..........  begin inserting new predefined function here


  # predefined pfunctions:
  # .pfunc definitions are used for all lines other than b-lines ( other devicelines , .param , .model , .tran .... )
  # syntax: always perl syntax !!!
  $pfidx=0; # startindex of user defined .pfunc lines
  # parameters placeholders are defined with __1 , __2 , __3 .....
  $pfuncname[0]="sgn";
  $panz_pm[0]=1;
  $pexpr[0]="((__1)<=>0)";
  $pfidx=1;
  $pfuncname[1]="neg";
  $panz_pm[1]=1;
  $pexpr[1]="(sgn(__1)*(sgn(__1)-1)/2)";
  $pfidx=2;
  $pfuncname[2]="pos";
  $panz_pm[2]=1;
  $pexpr[2]="(1-neg(__1))";
  $pfidx=3;
  $pfuncname[3]="pwrs";
  $panz_pm[3]=2;
  $pexpr[3]="(sgn(__1)*abs(__1)**(__2))";
  $pfidx=4;
  $pfuncname[4]="pwr";
  $panz_pm[4]=2;
  $pexpr[4]="(abs(__1)**(__2))";
  $pfidx=5;
  $pfuncname[5]="if";
  $panz_pm[5]=3;
  #$pexpr[5]="(pos((__1)-1)*(__2)+neg((__1)-1)*(__3))";
  $pexpr[5]="((__1)>0.5?(__2):(__3))";
  $pfidx=6;
  $pfuncname[6]="gt";
  $panz_pm[6]=2;
  $pexpr[6]="((__1)>(__2))";
  $pfidx=7;
  $pfuncname[7]="lt";
  $panz_pm[7]=2;
  $pexpr[7]="((__1)<(__2))";
  $pfidx=8;
  $pfuncname[8]="ge";
  $panz_pm[8]=2;
  $pexpr[8]="((__1)>=(__2))";
  $pfidx=9;
  $pfuncname[9]="le";
  $panz_pm[9]=2;
  $pexpr[9]="((__1)<=(__2))";
  $pfidx=10;
  $pfuncname[10]="not";
  $panz_pm[10]=1;
  $pexpr[10]="1-(abs(sgn(__1)))";
  $pfidx=11;
  $pfuncname[11]="eq";
  $panz_pm[11]=2;
  $pexpr[11]="((__1)==(__2))";
  $pfidx=12;
  $pfuncname[12]="ne";
  $panz_pm[12]=2;
  $pexpr[12]="((__1)!=(__2))";
  $pfidx=13;
  $pfuncname[13]="max";
  $panz_pm[13]=2;
  $pexpr[13]="((__1)>(__2)?(__1):(__2))";
  $pfidx=14;
  $pfuncname[14]="min";
  $panz_pm[14]=2;
  $pexpr[14]="((__1)<(__2)?(__1):(__2))";
  $pfidx=15;
  # special LIMIT2(v(vc),min(voff,von),max(voff,von))
  $pfuncname[15]="limit";
  $panz_pm[15]=3;
  $pexpr[15]="((__1)+gt((__1),(__3))*((__3)-(__1))+lt((__1),(__2))*((__2)-(__1)))";
  $pfidx=16;
  $pfuncname[16]="and";
  $panz_pm[16]=2;
  $pexpr[16]="((__1)&&(__2))";
  $pfidx=17;
  $pfuncname[17]="or";
  $panz_pm[17]=2;
  $pexpr[17]="((__1)||(__2))";
  $pfidx=18;
  $pfuncname[18]="xor";
  $panz_pm[18]=2;
  $pexpr[18]="(abs(sgn((__1)-(__2))))";
  $pfidx=19;
  $pfuncname[19]="pow";
  $panz_pm[19]=2;
  $pexpr[19]="((__1)**(__2))";
  $pfidx=20;
  $pfuncname[20]="stp"; # new
  $panz_pm[20]=1;
  $pexpr[20]="(0.5*(sgn(__1)+1))"; # stp(-0.1)=0 stp(0)=0.5 stp(0.1)=1
  $pfidx=21;
  $pfuncname[21]="tan"; # new
  $panz_pm[21]=1;
  $pexpr[21]="((sin(__1))/(cos(__1)))";
  $pfidx=22;
  $pfuncname[22]="cot"; # new
  $panz_pm[22]=1;
  $pexpr[22]="((cos(__1))/(sin(__1)))";
  $pfidx=23;
  $pfuncname[23]="atan"; # new
  $panz_pm[23]=1;
  $pexpr[23]="(atan2((__1),1))";
  $pfidx=24;
  $pfuncname[24]="asin"; # new
  $panz_pm[24]=1;
  $pexpr[24]="(atan((__1)/(sqrt(1-(__1)**2))))";
  $pfidx=25;
  $pfuncname[25]="acos"; # new
  $panz_pm[25]=1;
  $pexpr[25]="(pi/2-(asin((__1))))";
  $pfidx=26;
  $pfuncname[26]="sinh"; # new
  $panz_pm[26]=1;
  $pexpr[26]="(0.5*(exp(__1)-exp(-(__1))))";
  $pfidx=27;
  $pfuncname[27]="cosh"; # new
  $panz_pm[27]=1;
  $pexpr[27]="(0.5*(exp(__1)+exp(-(__1))))";
  $pfidx=28; #
  $pfuncname[28]="log10"; # in perl log means ln , log(10) is not defined
  $panz_pm[28]=1;
  $pexpr[28]="ln(__1)/ln(10)"; # conversion ln to log with ln
  $pfidx=29;
  $pfuncname[29]="ln"; # perl log(x) is ln(x) !!!!
  $panz_pm[29]=1;
  $pexpr[29]="(log(__1))";
  $pfidx=30; #
  $pfuncname[30]="u"; #
  $panz_pm[30]=1;
  $pexpr[30]="(stp(__1))";
  $pfidx=31; #
  $pfuncname[31]="uramp"; #
  $panz_pm[31]=1;
  $pexpr[31]="((__1)*pos(__1))";
  $pfidx=32; #
  $pfuncname[32]="buf"; #
  $panz_pm[32]=1;
  $pexpr[32]="(pos((__1)-0.5))";
  $pfidx=33;
  $pfuncname[33]="inv"; # perl log(x) is ln(x) !!!!
  $panz_pm[33]=1;
  $pexpr[33]="(1-(pos((__1)-0.5)))";
  $pfidx=34; # begin inserting new predefined function here

  # predefined in perl are :
  # int, rand(int) , srand(int) , log ( natural log = base e )
  # sqrt, abs , cos , sin , atan2(x,y) = 4 quadrant atan(x/y) (x,y in radiant)
  # bitright is >> , bitleft is << , bitand & ,bitor |, bitnot ^,
  # modulus is % , power is **
  # equal ==, notequal !=
  # logical not is not or !
  # logical xor is xor
  # logical and means  if-then XandY or X&&Y
  # logical or means   ifnot then XorY or X||Y
  # if-then-else X?Y:Z ,
  # if lower then -1 elseif greater then 1 else 0 A<=>B (compare) -1,1,0

  # some other fuctions possible to add ..
  ###############################
  # sec(x) = 1/cos(x)
  # csc(x) = 1/sin(x)
  # tanh(x) = sinh(x)/cosh(x)
  # cothx(x) = cosh(x)/sinh(x)
  # sech(x) = 1/cosh(x)
  # csch(x) = 1/sinh(x)
  ###############################
}

