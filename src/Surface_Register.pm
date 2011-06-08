#
# Copyright Alan C. Evans
# Professor of Neurology
# McGill University
#
##############################
#### Surface registration ####
##############################

# Once the cortical surfaces are produced, they need to be aligned with the
# surfaces of other brains in the data set so cortical thickness data could be
# compared across subjects. To achieve this, SURFREG performs a non-linear
# registration of the surfaces to a pre-defined template surface. This transform
# is then applied (by resampling) in native space.

package Surface_Register;
use strict;
use PMP::PMP;
use MRI_Image;

sub create_pipeline {
    my $pipeline_ref = @_[0];
    my $Prereqs = @_[1];
    my $image = @_[2];
    my $surfreg_model = @_[3];

    my $left_mid_surface = ${$image}->{mid_surface}{left};
    my $right_mid_surface = ${$image}->{mid_surface}{right};
    my $left_surfmap = ${$image}->{surface_map}{left};
    my $right_surfmap = ${$image}->{surface_map}{right};

          prereqs => $Prereqs } );

          prereqs => $Prereqs } );

# ---------------------------------------------------------------------------
#  Surface registration to left+right hemispheric averaged model.
# ---------------------------------------------------------------------------

    ${$pipeline_ref}->addStage( {
          name => "surface_registration_left",
          label => "register left mid-surface nonlinearly",
          inputs => [$left_mid_surface],
          outputs => [$left_surfmap],
          args => ["geom_surfreg.pl", "-clobber", "-min_control_mesh", "320",
                   "-max_control_mesh", "81920", "-blur_coef", "1.25", 
                   "-neighbourhood_radius", "2.8", "-target_spacing", "1.9", 
                   $surfreg_model, $left_mid_surface, $left_surfmap ],
          prereqs => $Prereqs });

    ${$pipeline_ref}->addStage( {
          name => "surface_registration_right",
          label => "register right mid-surface nonlinearly",
          inputs => [$right_mid_surface],
          outputs => [$right_surfmap],
          args => ["geom_surfreg.pl", "-clobber", "-min_control_mesh", "320",
                   "-max_control_mesh", "81920", "-blur_coef", "1.25",
                   "-neighbourhood_radius", "2.8", "-target_spacing", "1.9",
                   $surfreg_model, $right_mid_surface, $right_surfmap ],
          prereqs => $Prereqs });

    my $SurfReg_complete = [ "surface_registration_left",
                             "surface_registration_right" ];

    return( $SurfReg_complete );
}

##################################################
#### Resample the surfaces after registration ####
##################################################

sub resample_surfaces {
    my $pipeline_ref = @_[0];
    my $Prereqs = @_[1];
    my $image = @_[2];

    my $left_white_surface = ${$image}->{cal_white}{left};
    my $right_white_surface = ${$image}->{cal_white}{right};
    my $left_mid_surface = ${$image}->{mid_surface}{left};
    my $right_mid_surface = ${$image}->{mid_surface}{right};
    my $left_gray_surface = ${$image}->{gray}{left};
    my $right_gray_surface = ${$image}->{gray}{right};

    my $left_surfmap = ${$image}->{surface_map}{left};
    my $right_surfmap = ${$image}->{surface_map}{right};

    my $left_white_surface_rsl = ${$image}->{cal_white_rsl}{left};
    my $right_white_surface_rsl = ${$image}->{cal_white_rsl}{right};
    my $left_mid_surface_rsl = ${$image}->{mid_surface_rsl}{left};
    my $right_mid_surface_rsl = ${$image}->{mid_surface_rsl}{right};
    my $left_gray_surface_rsl = ${$image}->{gray_rsl}{left};
    my $right_gray_surface_rsl = ${$image}->{gray_rsl}{right};

    ${$pipeline_ref}->addStage( {
          name => "surface_resample_left_white",
          label => "resample left white surface",
          inputs => [$left_white_surface, $left_surfmap],
          outputs => [$left_white_surface_rsl],
          args => [ "sphere_resample_obj", "-clobber", $left_white_surface,
                    $left_surfmap, $left_white_surface_rsl ],
          prereqs => $Prereqs });

    ${$pipeline_ref}->addStage( {
          name => "surface_resample_right_white",
          label => "resample right white surface",
          inputs => [$right_white_surface, $right_surfmap],
          outputs => [$right_white_surface_rsl],
          args => [ "sphere_resample_obj", "-clobber", $right_white_surface,
                    $right_surfmap, $right_white_surface_rsl ],
          prereqs => $Prereqs });

    ${$pipeline_ref}->addStage( {
          name => "surface_resample_left_gray",
          label => "resample left gray surface",
          inputs => [$left_gray_surface, $left_surfmap],
          outputs => [$left_gray_surface_rsl],
          args => [ "sphere_resample_obj", "-clobber", $left_gray_surface,
                    $left_surfmap, $left_gray_surface_rsl ],
          prereqs => $Prereqs });

    ${$pipeline_ref}->addStage( {
          name => "surface_resample_right_gray",
          label => "resample right gray surface",
          inputs => [$right_gray_surface, $right_surfmap],
          outputs => [$right_gray_surface_rsl],
          args => [ "sphere_resample_obj", "-clobber", $right_gray_surface,
                    $right_surfmap, $right_gray_surface_rsl ],
          prereqs => $Prereqs });

    ${$pipeline_ref}->addStage( {
          name => "surface_resample_left_mid",
          label => "resample left mid surface",
          inputs => [$left_mid_surface, $left_surfmap],
          outputs => [$left_mid_surface_rsl],
          args => [ "sphere_resample_obj", "-clobber", $left_mid_surface,
                    $left_surfmap, $left_mid_surface_rsl ],
          prereqs => $Prereqs });

    ${$pipeline_ref}->addStage( {
          name => "surface_resample_right_mid",
          label => "resample right mid surface",
          inputs => [$right_mid_surface, $right_surfmap],
          outputs => [$right_mid_surface_rsl],
          args => [ "sphere_resample_obj", "-clobber", $right_mid_surface,
                    $right_surfmap, $right_mid_surface_rsl ],
          prereqs => $Prereqs });

    my $SurfResample_complete = [ "surface_resample_left_white",
                                  "surface_resample_right_white",
                                  "surface_resample_left_gray",
                                  "surface_resample_right_gray",
                                  "surface_resample_left_mid",
                                  "surface_resample_right_mid" ];

    return( $SurfResample_complete );
}

#####################################################
#### Compute surface areas on resampled surfaces ####
#####################################################

sub resampled_surface_areas {
    my $pipeline_ref = @_[0];
    my $Prereqs = @_[1];
    my $image = @_[2];
    my $surfreg_model = @_[3];

    my $fwhm = ${$image}->{rsl_area_fwhm};
    my $t1_tal_xfm = ${$image}->{t1_tal_xfm};
    my $left_mid_surface_rsl = ${$image}->{mid_surface_rsl}{left};
    my $right_mid_surface_rsl = ${$image}->{mid_surface_rsl}{right};
    my $left_surface_area_rsl = ${$image}->{surface_area_rsl}{left};
    my $right_surface_area_rsl = ${$image}->{surface_area_rsl}{right};

    ${$pipeline_ref}->addStage( {
          name => "surface_area_rsl_left_mid",
          label => "surface area on resampled left mid surface",
          inputs => [$left_mid_surface_rsl,$t1_tal_xfm],
          outputs => [$left_surface_area_rsl],
          args => [ "cortical_area_stats", $left_mid_surface_rsl,
                    $surfreg_model, $t1_tal_xfm, $fwhm, 
                    $left_surface_area_rsl],
          prereqs => $Prereqs });

    ${$pipeline_ref}->addStage( {
          name => "surface_area_rsl_right_mid",
          label => "surface area on resampled right mid surface",
          inputs => [$right_mid_surface_rsl,$t1_tal_xfm],
          outputs => [$right_surface_area_rsl],
          args => [ "cortical_area_stats", $right_mid_surface_rsl,
                    $surfreg_model, $t1_tal_xfm, $fwhm, 
                    $right_surface_area_rsl],
          prereqs => $Prereqs });

    my $SurfaceAreas_complete = [ "surface_area_rsl_left_mid",
                                  "surface_area_rsl_right_mid" ];

    return( $SurfaceAreas_complete );
}


#######################################################
#### Compute surface volumes on resampled surfaces ####
#######################################################

sub resampled_surface_volumes {
    my $pipeline_ref = @_[0];
    my $Prereqs = @_[1];
    my $image = @_[2];
    my $surfreg_model = @_[3];

    my $fwhm = ${$image}->{rsl_volume_fwhm};
    my $t1_tal_xfm = ${$image}->{t1_tal_xfm};
    my $left_white_surface_rsl = ${$image}->{cal_white_rsl}{left};
    my $right_white_surface_rsl = ${$image}->{cal_white_rsl}{right};
    my $left_gray_surface_rsl = ${$image}->{gray_rsl}{left};
    my $right_gray_surface_rsl = ${$image}->{gray_rsl}{right};
    my $left_surface_volume_rsl = ${$image}->{surface_volume_rsl}{left};
    my $right_surface_volume_rsl = ${$image}->{surface_volume_rsl}{right};

    ${$pipeline_ref}->addStage( {
          name => "surface_volume_rsl_left",
          label => "surface volumes on resampled left hemisphere",
          inputs => [$t1_tal_xfm,$left_white_surface_rsl,$left_gray_surface_rsl],
          outputs => [$left_surface_volume_rsl],
          args => [ "cortical_volume_stats", $left_white_surface_rsl,
                    $left_gray_surface_rsl, $surfreg_model, $t1_tal_xfm,
                    $fwhm, $left_surface_volume_rsl],
          prereqs => $Prereqs });

    ${$pipeline_ref}->addStage( {
          name => "surface_volume_rsl_right",
          label => "surface volumes on resampled right mid hemisphere",
          inputs => [$t1_tal_xfm,$right_white_surface_rsl,$right_gray_surface_rsl],
          outputs => [$right_surface_volume_rsl],
          args => [ "cortical_volume_stats", $right_white_surface_rsl,
                    $right_gray_surface_rsl, $surfreg_model, $t1_tal_xfm,
                    $fwhm, $right_surface_volume_rsl],
          prereqs => $Prereqs });

    my $SurfaceVolumes_complete = [ "surface_volume_rsl_left",
                                    "surface_volume_rsl_right" ];

    return( $SurfaceVolumes_complete );
}


1;
