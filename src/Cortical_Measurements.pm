# Compute the cortical thickness.

package Cortical_Measurements;
use strict;
use PMP::PMP;
use MRI_Image;

sub thickness {

    my $pipeline_ref = @_[0];
    my $Prereqs = @_[1];
    my $image = @_[2];

    my $tkernel = ${$image}->{tkernel};
    my $tmethod = ${$image}->{tmethod};

    my $white_left = ${$image}->{white}{cal_left};
    my $white_right = ${$image}->{white}{cal_right};
    my $gray_left = ${$image}->{gray}{left};
    my $gray_right = ${$image}->{gray}{right};

    my $native_rms_left = ${$image}->{rms}{left};
    my $native_rms_right = ${$image}->{rms}{right};

    my $t1_tal_xfm = ${$image}->{t1_tal_xfm};
    my $stx_labels_masked = ${$image}->{stx_labels_masked};

    #################################################################################
    ##### Calculation of the cortical thickness and cortex area in native space #####
    #################################################################################

    ###########################
    ##### Left hemisphere #####
    ###########################

    ${$pipeline_ref}->addStage(
         { name => "thickness_left",
         label => "native thickness",
         inputs => [$white_left, $gray_left, $t1_tal_xfm],
         outputs => [$native_rms_left],
         args => ["cortical_thickness", "-${tmethod}", "-fwhm", ${tkernel}, 
                  "-transform", $t1_tal_xfm,
                  $white_left, $gray_left, $native_rms_left],
         prereqs => $Prereqs });

    ############################
    ##### Right hemisphere #####
    ############################

    ${$pipeline_ref}->addStage(
         { name => "thickness_right",
         label => "native thickness",
         inputs => [$white_right, $gray_right, $t1_tal_xfm],
         outputs => [$native_rms_right],
         args => ["cortical_thickness", "-${tmethod}", "-fwhm", ${tkernel}, 
                  "-transform", $t1_tal_xfm,
                  $white_right, $gray_right, $native_rms_right],
         prereqs => $Prereqs });

    my $Cortical_Thickness_complete = ["thickness_left", "thickness_right"];

    return( $Cortical_Thickness_complete );

}

sub lobe_area {

    my $pipeline_ref = @_[0];
    my $Prereqs = @_[1];
    my $image = @_[2];

    my $white_left = ${$image}->{white}{cal_left};
    my $white_right = ${$image}->{white}{cal_right};
    my $gray_left = ${$image}->{gray}{left};
    my $gray_right = ${$image}->{gray}{right};

    my $lobe_area_left = ${$image}->{lobe_areas}{left};
    my $lobe_area_right = ${$image}->{lobe_areas}{right};

    my $native_rms_left = ${$image}->{rms}{left};
    my $native_rms_right = ${$image}->{rms}{right};
    my $lobe_thickness_left = ${$image}->{lobe_thickness}{left};
    my $lobe_thickness_right = ${$image}->{lobe_thickness}{right};

    my $t1_tal_xfm = ${$image}->{t1_tal_xfm};
    my $stx_labels_masked = ${$image}->{stx_labels_masked};

    #################################################################################
    ##### Calculation of the cortical thickness and cortex area in native space #####
    #################################################################################

    ###########################
    ##### Left hemisphere #####
    ###########################

    my @ExtraInputsLeft;
    my @ExtraInputsRight;
    my @ExtraOutputsLeft;
    my @ExtraOutputsRight;
    if( ${$image}->{tkernel} && ${$image}->{tmethod} ) {
      push @ExtraInputsLeft, ( $native_rms_left );
      push @ExtraInputsRight, ( $native_rms_right );
      push @ExtraOutputsLeft, ( $lobe_thickness_left );
      push @ExtraOutputsRight, ( $lobe_thickness_right );
    } else {
      $native_rms_left = "none";
      $native_rms_right = "none";
      $lobe_thickness_left = "none";
      $lobe_thickness_right = "none";
    }

    ${$pipeline_ref}->addStage(
         { name => "lobe_area_left",
         label => "native lobe area",
         inputs => [$white_left, $gray_left, $t1_tal_xfm, @ExtraInputsLeft ],
         outputs => [$lobe_area_left, @ExtraOutputsLeft],
         args => ["lobe_area", "-transform", $t1_tal_xfm,
                  $white_left, $gray_left, $native_rms_left,
                  $stx_labels_masked, $lobe_area_left, $lobe_thickness_left ],
         prereqs => $Prereqs });

    ${$pipeline_ref}->addStage(
         { name => "lobe_area_right",
         label => "native lobe area",
         inputs => [$white_right, $gray_right, $t1_tal_xfm, @ExtraInputsRight ],
         outputs => [$lobe_area_right, @ExtraOutputsRight],
         args => ["lobe_area", "-transform", $t1_tal_xfm,
                  $white_right, $gray_right, $native_rms_right,
                  $stx_labels_masked, $lobe_area_right, $lobe_thickness_right ],
         prereqs => $Prereqs });

    ############################
    ##### Right hemisphere #####
    ############################

    my $Lobe_Area_complete = ["lobe_area_left", "lobe_area_right"];

    return( $Lobe_Area_complete );

}
1;