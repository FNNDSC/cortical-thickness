#! /usr/bin/perl
#
# Copyright Alan C. Evans
# Professor of Neurology
# McGill University
#

use strict;
use warnings "all";

require "$ENV{RESOURCES_DIR}/lib/surface-extraction/utils.pl";
require "$ENV{RESOURCES_DIR}/lib/surface-extraction/deform_utils.pl";

use Getopt::Tabular;
use MNI::Startup;
use MNI::FileUtilities;
use MNI::Spawn;
use MNI::FileUtilities qw(check_output_dirs);
use File::Basename;

MNI::Spawn::RegisterPrograms
  ( [qw/  rm
     cp
     param2xfm
     transform_objects
     convert_object
     subdivide_polygons
     surface_fit
     set_object_colour/ ] )
  or exit 1;

# --- set the help & usage strings ---
my $help = <<HELP;
Required parameters:
  white.obj  : white matter surface (used to generate Laplacian field)
  gray.obj   : gray matter surface (output)
  field.mnc  : Laplacian field for gray matter
Optional parameters:
  [-refine]  : to generate the gray surface with 327680 triangles 
               starting from white 81920
  [-hiresonly] : to generate the gray surface with 327680 triangles only
                 starting from gray 81920
  [-log]     : log file for stdout
  [-schedule]: print the schedule to see the steps
  [-left]      : extract a left surface
  [-right]     : extract a right surface
  [-init]      : initial surface (on a restart)
HELP

my $license = <<LICENSE;
Copyright Alan C. Evans
Professor of Neurology
McGill University

LICENSE

my $usage = <<USAGE;
Usage: $ProgramName white.obj gray.obj field.mnc
       [-refine] [-hiresonly] [-log log_file] [-schedule]
       [-left] [-right] [-init initial_white.obj]
       $ProgramName -help to list options

$license
USAGE

Getopt::Tabular::SetHelp( $help, $usage );

my $side = undef;
my $refine = 0;
my $hiresonly = 0;
my $start_n = 0;
my $end_n = 9999;
my $print_schedule = 0;
my $logfile;
my $InitGray = undef;

# --- process options ---
my @options = 
  ( @DefaultArgs,     # from MNI::Startup
  ['-refine', 'boolean', 0, \$refine, 
   "Create a high-resolution surface at 327680 polygons starting from white 81920"],
  ['-hiresonly', 'boolean', 0, \$hiresonly, 
   "Create a high-resolution surface at 327680 polygons starting from gray 81920"],
  ['-log', 'string', 1, \$logfile, "Log file" ],
  ['-schedule', 'boolean', 0, \$print_schedule, "Print schedule"],
  ['-left', 'const', "Left", \$side, "Expand left surface"],
  ['-right', 'const', "Right", \$side, "Expand right surface"],
  ['-init', 'string', 1, \$InitGray, "Initial gray surface for a restart"],
  );

GetOptions( \@options, \@ARGV ) 
  or exit 1;
die "$usage\n" unless @ARGV >= 3;

    my ($i, $step, $size, $sw, $n_iters, $iter_inc);
    my ($si_step, $self_weight, $self_dist);
    my ($laplacian_isovalue, $laplacian_sampling, $laplacian_weight);
    my ($self2, $surf2_info, $n_failures, $iter, $ni, $command, $ret);
    my ($laplace_info);

    my $white_surface = shift;
    my $gray_surface = shift;
    my $laplacian_file = shift;

    my $log = "";
    if( defined($logfile) ) {
      $log = " -log $logfile";
    }

# self : distance from self intersection;
# iso : isovalue of Laplacian field to converge to
# l_s : do subsampling (0=none, n=#points extra along edge);
#       (helps to get through isolated csf voxels in insula region,
#       but must finish off the job without subsampling)
# l_w : weight for Laplacian field: large value means tighter fit,
#       but it seems that a small value is better convergence wise
#       to ensure mesh quality.
#   
# Basically, choose a small enough value of l_w to see some 
# convergence in phi. The smaller l_w, the slower the convergence,
# but it will converge nonetheless. Then choose a large enough
# value of sw (stretch) such as to maintain mesh smoothness and
# see convergence in stretch constraint as well as in Laplacian
# constraint. 
# Note: need to increase sw with l_s=1.0 to keep smoothness of
#       the mesh, otherwise mesh becomes distorted.
# Note: use subsampling (l_s=1) till the end to prevent surface
#       from detaching from bottom of sulci.

    my @schedule;
    @schedule = (
      #size   sw   n_it  inc  si     sw  self  iso   l_s  l_w
      #----- ----  ----  ---  --    ---  ----  ---   ---  ----
       #20480, 5e3,  200, 50, 1.0,   1e1,  .01,   10,  1.0, 5e-3,
       81920, 5e3,  100, 50, 1.0,   1e1,  .01,   10,  1.0, 5e-5,
    );

    my $sched_size =  10;
    my $num_steps = @schedule / $sched_size;
    $end_n = $num_steps - 1;

    if( $print_schedule ) {
        for( $i = 0;  $i < @schedule;  $i += $sched_size ) {
            $step = $i / $sched_size;
            ( $size, $sw, $n_iters, $iter_inc,
              $si_step, $self_weight, $self_dist, 
              $laplacian_isovalue, $laplacian_sampling, 
              $laplacian_weight ) = @schedule[$i..$i+$sched_size-1];
            print( "Step $step : $size polygons, stetch weight $sw, " );
            print( "Laplace weight $laplacian_weight\n" );
        }
        die "\n";
    }

    # ignore initial steps at 81920 if hiresonly.
    if( $hiresonly ) {
      for( $i = 0;  $i < @schedule;  $i += $sched_size ) {
        $step = $i / $sched_size;
        if( $schedule[$i] == 327680 ) {
          $start_n = $step;
          last;
        }
      }
    }

    # ignore last few steps if no hi-res surface is desired.
    if( !( $refine || $hiresonly ) ) {
      for( $i = 0;  $i < @schedule;  $i += $sched_size ) {
        $step = $i / $sched_size;
        if( $schedule[$i] == 327680 ) {
          $end_n = $step - 1;
          last;
        }
      }
    }

    if( ! defined($laplacian_file) ) {
      die "$usage\n";
    }
    if( ! defined($gray_surface) ) {
      die "$usage\n";
    }
    if( ! defined($white_surface) ) {
      die "$usage\n";
    }

    #--- remove whatever suffix name may have

    my @objsuffix = ( ".obj", "_320", "_1280", "_5120", "_20480", "_81920", "_327680" );
    my $gray_dir = dirname( $gray_surface );
    my $gray_prefix = basename( $gray_surface, @objsuffix );
    $gray_prefix = "${gray_dir}/${gray_prefix}";

    #--- remove whatever suffix name may have
    my $white_dir = dirname( $white_surface );
    my $white_prefix = basename( $white_surface, @objsuffix );
    $white_prefix = "${white_dir}/${white_prefix}";

    my $n_polygons = `print_n_polygons $white_surface`;
    chop( $n_polygons );

    check_output_dirs($TmpDir);

    my $fit = "surface_fit ";

    my $self_dist2 = 0.005;   # was 0.01
    my $self_weight2 = 1e07;
    my $n_selfs = 9;
    my $self_factor = 1.0;

    my $stop_threshold = 1e-4;
    my $stop_iters = 50;

    my $n_per = 1;
    my $tolerance = 1.0e-3;
    my $f_tolerance = 1.0e-6;

    my $stretch_scale = 1;

    my $prev_n;

    # Check for a restart.
    if( $start_n == 0 ) {
      #--- no restart: start at beginning of schedule

      #--- Create a starting gray surface at $prev_n polygons
      #--- from the corresponding white surface.

      $prev_n = $schedule[0];
      $size = $prev_n;
      if( !( -e "${white_prefix}_${size}.obj" ) ) {
        subdivide_mesh( $white_surface, $size, "${white_prefix}_${size}.obj", 
                        $side );
      }
      $white_surface = "${white_prefix}_${size}.obj";
      $gray_surface = "${gray_prefix}_${size}.obj";
      Spawn(["set_object_colour", $white_surface, $gray_surface, "white"]);
    } else {
      #--- continue execution, starting at this step.
      $prev_n = $schedule[($start_n-1)*$sched_size];
      $size = $schedule[$start_n*$sched_size];
      $gray_surface = "${gray_prefix}_${size}.obj";
      $white_surface = "${white_prefix}_${size}.obj";

      if( $prev_n < $size ) {
        # obtain a starting white surface at new size
        if( ! ( -e $white_surface ) ) {
          if( ! ( -e "${white_prefix}_${prev_n}.obj" ) ) {
            die "White surface $white_surface does not exist.\n";
          } else {
            subdivide_mesh( "${white_prefix}_${prev_n}.obj", $size,
                            $white_surface, $side );
          }
        }
        # subdivide previous gray surface to new size. if it does not exist,
        # create one from the white at the new size. if the gray surface
        # already exists, continue from it.
        if( ! ( -e "${gray_prefix}_${prev_n}.obj" ) ) {
          Spawn(["set_object_colour", $white_surface, $gray_surface, "white"]);
        } else {
          subdivide_mesh( "${gray_prefix}_${prev_n}.obj", $size,
                          $gray_surface, $side );
        }
        $prev_n = $size;
      } else {
        # continue from current gray surface. if it does not exist,
        # create one from the white.
        if( ! ( -e $white_surface ) ) {
          die "White surface $white_surface does not exist.\n";
        }
        if( ! ( -e $gray_surface ) ) {
          Spawn(["set_object_colour", $white_surface, $gray_surface, "white"]);
        }
      }
    }

#------ loop over each schedule

    for( $i = 0;  $i < @schedule;  $i += $sched_size ) {

        $step = $i / $sched_size;
        if( $step > $end_n ) {
          last;
        }

        #--- get the components of the deformation schedule entry

        ( $size, $sw, $n_iters, $iter_inc,
          $si_step, $self_weight, $self_dist, 
          $laplacian_isovalue, $laplacian_sampling,
          $laplacian_weight ) = @schedule[$i..$i+$sched_size-1];

        if( $step < $start_n ) {
            $prev_n = $size;
            next;
        }

        $sw *= $stretch_scale;
        $self_weight *= $self_factor;

        $self2 = get_self_intersect( $self_weight, $self_weight2, $n_selfs,
                                     $self_dist, $self_dist2 );

        #--- if the schedule size is greater than the current number of
        #--- polygons in the deforming surface, subdivide the deforming surface

        if( $size > $prev_n ) {

          #--- subdivide corresponding white surface, needed by surface_fit
          #--- in surf_surf check

          $white_surface = "${white_prefix}_${size}.obj";
          if( ! ( -e $white_surface ) ) {
            if( ! ( -e "${white_prefix}_${prev_n}.obj" ) ) {
              die "Cannot create $white_surface from ${white_prefix}_${prev_n}.obj.\n";
            } else {
              subdivide_mesh( "${white_prefix}_${prev_n}.obj", $size,
                              $white_surface, $side );
            }
          }

          # subdivide current gray surface to new size. if it does not exist,
          # create one from the white at the new size. if the gray surface
          # already exists, continue from it.

          $gray_surface = "${gray_prefix}_${size}.obj";
          if( ! ( -e "${gray_prefix}_${prev_n}.obj" ) ) {
            Spawn(["set_object_colour", $white_surface, $gray_surface, "white"]);
          } else {
            subdivide_mesh( "${gray_prefix}_${prev_n}.obj", $size,
                            $gray_surface, $side );
          }

        }
        $prev_n = $size;

        print( "Fitting polygons, max $n_iters iters.\n" );

        $laplace_info = " -laplacian $laplacian_file $laplacian_weight 0 " .
                        "$laplacian_isovalue $laplacian_sampling ";

        if( $iter_inc <= 0 )  { $iter_inc = $n_iters; }

        $surf2_info = " -surface ${gray_surface} ${gray_surface} ${white_surface}" .
          " -stretch $sw ${white_surface} -1.0 0 0 0".
          " $self2 ".
          " $laplace_info ";

        $n_failures = 0;


        # Make sure the gray surface is in binary mode.
        if( -e $gray_surface ) {
          my $ret = `convert_object $gray_surface ${TmpDir}/gray_surf_test.obj`;
          if( $ret =~ /ASCII to BINARY/ ) {
            `mv ${TmpDir}/gray_surf_test.obj $gray_surface`;
          } else {
            unlink( "${TmpDir}/gray_surf_test.obj" );
          }
        }

        for( $iter = 0;  $iter < $n_iters;  $iter += $iter_inc ) {
            system( "echo Step ${size}: $iter / $n_iters    $sw  $laplacian_isovalue" );

            $ni = $n_iters - $iter;
            if( $ni > $iter_inc )  { $ni = $iter_inc; }

            $command = "$fit -mode three $surf2_info ".
                       " -step $si_step " .
                       " -fitting $ni $n_per $tolerance " .
                       " -ftol $f_tolerance " .
                       " -stop $stop_threshold $stop_iters ".
                       " $log ";

            $ret = system_call( "$command", 1 );

            system_call( "measure_surface_area $gray_surface" );

            if( $ret == 1 ) {
                ++$n_failures;

                if( $n_failures == 2 )
                    { last; }
            } else {
                $n_failures = 0;
            }
        }
    }

    Spawn( ["convert_object", $gray_surface, $gray_surface] );

    print( "Surface extraction finished.\n" );

    clean_up();


sub subdivide_mesh {

  my $input = shift;
  my $npoly = shift;
  my $output = shift;
  my $side = shift;

  my $npoly_input = `print_n_polygons $input`;
  chomp( $npoly_input );
  if( $side eq "Left" ) {
    Spawn( ["subdivide_polygons", $input, $output, $npoly] );
  }
  if( $side eq "Right" ) {
    # flip right as left first before subdividing, then flip back.
    Spawn( ["param2xfm", '-clobber', '-scales', -1, 1, 1,
            "${TmpDir}/flip.xfm"] );
    my $input_flipped = "${TmpDir}/right_flipped.obj";
    Spawn( ["transform_objects", $input,
            "${TmpDir}/flip.xfm", $input_flipped] );
    Spawn( ["subdivide_polygons", $input_flipped, $output, $npoly] );
    Spawn( ["transform_objects", $output,
            "${TmpDir}/flip.xfm", $output] );  # flip.xfm is its own inverse
    unlink( $input_flipped );
    unlink( "${TmpDir}/flip.xfm" );
  }

}

