#! /usr/bin/env perl
#
# Configurable surface register 
#
# Oliver Lyttelton oliver@bic.mni.mcgill.ca

#

use strict;
use warnings "all";
use Getopt::Tabular;
use File::Basename;
use File::Temp qw/ tempdir /;


my($Help, $Usage, $me);
my(@opt_table, %opt, @args, $tmpdir);

$me = &basename($0);
%opt = (
   'verbose'   => 0,
   'clobber'   => 0,
   'nearest_neighbour' =>0
   );

$Help = <<HELP;
|    $me fully configurable surface fitting...
| 
| Problems or comments should be sent to: oliver\@bic.mni.mcgill.ca
HELP

$Usage = "Usage: $me [options] source_to_target_sm target_field output_source_field\n".
         "       $me -help to list options\n\n";

@opt_table = (
   ["-verbose", "boolean", 0, \$opt{verbose},
      "be verbose" ],
   ["-clobber", "boolean", 0, \$opt{clobber},
      "clobber existing files" ],
   ["-nearest_neighbour", "boolean", 0, \$opt{nearest_neighbour},
      "choose nearest neighbour resampling" ],
   );

# Check arguments
&Getopt::Tabular::SetHelp($Help, $Usage);
&GetOptions (\@opt_table, \@ARGV) || exit 1;
die $Usage if($#ARGV != 2);
my $source_to_target_mapping= shift(@ARGV);
my $target_field= shift(@ARGV);
my $output_source_field= shift(@ARGV);


# check for files
die "$me: Couldn't find input file: $source_to_target_mapping\n" if (!-e $source_to_target_mapping);
die "$me: Couldn't find input file: $target_field\n" if (!-e $target_field);

if(-e $output_source_field && !$opt{clobber}){
   die "$me: $output_source_field exists, -clobber to overwrite\n";
   }

# make tmpdir
$tmpdir = &tempdir( "$me-XXXXXXXX", TMPDIR => 1, CLEANUP => 1 );

open INOBJ,$target_field;
my @inobjarray = <INOBJ>;
my $target_field_size = ($#inobjarray+1)*2-4;
 if ($inobjarray[0] eq "\n" ||$inobjarray[0]  eq " \n")  {$target_field_size =   $target_field_size-2;}
close(INOBJ);

open INOBJ,$source_to_target_mapping;
@inobjarray = <INOBJ>;
my $control_mapping_mesh = $inobjarray[2]*2-4;
my $target_mapping_mesh = $inobjarray[3]*2-4;
close(INOBJ);


if ($target_mapping_mesh!=$target_field_size) {
    die "$me: target mapping mesh ($target_mapping_mesh) and target field ($target_field_size) have different sizes , insert coin to play again";
}




my $target_mesh_size =$target_mapping_mesh;  #This should get picked up from the sm and the target field file and checked...
#my  $control_mesh_size = $target_mesh_size/(4*$initial_mesh_size);  #unless a surface mapping is already specified....
my $control_mesh_size = $control_mapping_mesh;   #This should be picked up from the surface_mapping

my $control_mesh = "${tmpdir}/control_mesh.obj";
my $target_mesh = "${tmpdir}/target_mesh.obj";
my $old_mapping = "${tmpdir}/old_mapping.sm";;
 my $refined_mapping = "${tmpdir}/refined_mapping.sm";
 
&do_cmd('cp', $source_to_target_mapping, $refined_mapping);
#Then we make the control mesh and the sphere mesh
&do_cmd('create_tetra',$control_mesh,0,0,0,1,1,1,$control_mesh_size);
# and the sphere mesh
&do_cmd('create_tetra',$target_mesh,0,0,0,1,1,1,$target_mesh_size);

while ($control_mesh_size!=$target_mesh_size){
$control_mesh_size = $control_mesh_size*4;
if ($control_mesh_size>$target_mesh_size){ die "$me:control mesh is not a subsampling of target mesh, dieing horribly\n"; }
&do_cmd('cp', $refined_mapping, $old_mapping); 
 &do_cmd('create_tetra',$control_mesh,0,0,0,1,1,1,$control_mesh_size);
 &do_cmd('refine-surface-map',$old_mapping, $control_mesh,$target_mesh, $refined_mapping);
}

#now we can do the resample 
&do_cmd('surface-resample',$target_mesh,$target_mesh,$target_field,$refined_mapping,$output_source_field);



sub do_cmd { 
   print STDOUT "@_\n" if $opt{verbose};
   system(@_) == 0 or die;
}












