#!/usr/bin/perl
# sort_res.pl - Script to group & sort lsof output by resource
#
# Copyright (c) 2004, 2005 - Fabian Frederick <fabian.frederick@gmx.fr>
#
# This program/include file is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License as published
# by the Free Software Foundation; either version 2 of the License, or
# (at your option) any later version.
#
# This program/include file is distributed in the hope that it will be
# useful, but WITHOUT ANY WARRANTY; without even the implied warranty
# of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program (in the main directory of the Linux-NTFS
# distribution in the file COPYING); if not, write to the Free Software
# Foundation,Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
#
# Note :
#	-This script uses lsof released by Victor A. Abell
#	-lsof path recovery comes from standard perl scripts in there.
#
# Usage :
#	perl sort_res.pl -> display used resources + size
#	or perl sort_res.pl <program name>
#
# 12/2005 (FabF)
#	-size reset in loop (script was broken in 4.76)
#	-isexec looking in .. (like other scripts)
#	-display for one or all processes
#	-removing useless line number arg.
#	-display global size

my @args = @_;

# Set path to lsof.
if (($LSOF = &isexec("../lsof")) eq "") {    # Some distros use lsof
						    # out of $PATH
    if (($LSOF = &isexec("lsof")) eq "") {	    # Then try . and $PATH
	if (($LSOF = &isexec("../lsof")) eq "") {    # Then try ..
	    print "can't execute $LSOF\n"; exit 1
	}
    }
}

if ($ARGV[0] ne ""){
    $cmd="$LSOF -nPl -Fcns -c".$ARGV[0]."|";
}else{
    $cmd="$LSOF -nPl -Fcns|";
}

#Parse lsof output to gather command, resource name, pid and size
#Some extradata stand to keep script genericity
$i=0;
if (open(FILE, $cmd)){
    while (defined ($line=<FILE>)){
	$cline=$line;
	$cline =~ s"^(.)"";
	$cline =~ s/^\s+|\s+$//g;
	if($line=~m/^p/){
	    $pid=$cline;
	}else{
	    if($line=~/^s/){
		$size = $cline;
	    }else{
		if($line=~/^c/){
		    $command = $cline;
		}else{
		    if($line=~/^n/){
			$name = $cline;
			$data{$i} = { command => $command, name => $name,
				      pid => $pid , size => $size};
			$size=0;
			$i = $i+1;
		    }
		}
	    }
	}
    }
}

#Resource name sorting
sub byresname { $data{$a}{name} cmp $data{$b}{name}}
@ks=sort byresname (keys %data);

#Resource grouping
$i=0;
$cname="a";
foreach $k (@ks){
    if ($data{$k}{name} ne $cname){
	$dgroup{$i} = { name => $data{$k}{name}, size => $data{$k}{size}};
	$cname = $data{$k}{name};
	$i++;
    }
}

#Size sort on resource hash
sub bysize { $dgroup{$a}{size} <=> $dgroup{$b}{size} }
@ks=sort bysize (keys %dgroup);
$gsize=0;
printf("  -- KB --  -- Resource --\n", );
foreach $k (@ks){
	printf("%10d  %s\n", $dgroup{$k}{size}/1024, $dgroup{$k}{name});
	$gsize+=$dgroup{$k}{size};
}

printf("Total KB : %10d\n", $gsize/1024);
## isexec($path) -- is $path executable
#
# $path   = absolute or relative path to file to test for executabiity.
#	    Paths that begin with neither '/' nor '.' that arent't found as
#	    simple references are also tested with the path prefixes of the
#	    PATH environment variable.

sub
isexec {
    my ($path) = @_;
    my ($i, @P, $PATH);

    $path =~ s/^\s+|\s+$//g;
    if ($path eq "") { return(""); }
    if (($path =~ m#^[\/\.]#)) {
	if (-x $path) { return($path); }
	return("");
    }
    $PATH = $ENV{PATH};
    @P = split(":", $PATH);
    for ($i = 0; $i <= $#P; $i++) {
	if (-x "$P[$i]/$path") { return("$P[$i]/$path"); }
    }
    return("");
}
