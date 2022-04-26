#!/usr/bin/env perl

use strict;
use POSIX;
use MNI::Startup;
use Getopt::Tabular;
use MNI::Spawn;
use MNI::DataDir;
use MNI::FileUtilities qw(check_output_dirs);
use File::Temp qw/ tempdir /;

my $verbose = 1;

print "Create a Laplacian field in a cortical layer outside a current surface\n";
print "Usage:\n";
print "./laplace.pl labels.mnc white.obj label_value laplace.mnc\n";
print "  labels.mnc: csf=1, gm=2, white=3, next layer=4, etc...\n";
print "  white.obj: current surface on the inner layer\n";
print "  label_value: value of label to be included in Laplacian field\n";
print "  laplace.mnc: name for output file for Laplacian field\n";

my $labels = shift;
my $surf = shift;
my $value = shift;
my $output = shift;

# make tmpdir
my $tmpdir = &tempdir( "laplace-XXXXXXXX", TMPDIR => 1, CLEANUP => 1 );

#my $tmpdir = './temp';

if( $value <= 0 ) {
  die "Label value of $value must be positive.\n";
}

my $surf_mask = "${tmpdir}/surface_mask.mnc";
&run( 'surface_mask2', '-binary_mask', $labels, $surf, $surf_mask );

my $min_value = $value - 0.5;
my $max_value = $value + 0.5;
&run( 'dilate_volume', $surf_mask, $surf_mask, 1, 6, 1, $labels, 
      $min_value, $max_value );
&run( 'dilate_volume', $surf_mask, $surf_mask, 0, 6, 2 );

my $negative_mask = "${tmpdir}/negative_mask.mnc";
&run( 'minccalc', '-quiet', '-clobber', '-unsigned', '-short', 
      '-expression', 'A[0]<0.5', $surf_mask, $negative_mask );

my $chamfer = "${tmpdir}/chamfer.mnc";
&run( 'mincchamfer', '-quiet', '-max_dist', 5, $negative_mask, $chamfer );
unlink( $negative_mask );

my $grid = "${tmpdir}/grid.mnc";
&run( 'minccalc', '-quiet', '-clobber', '-signed', '-short', 
      '-expression', "if(A[1]>0.5){-A[2]}else{if(A[0]>$value-0.5){5}else{10}}",
      $labels, $surf_mask, $chamfer, $grid );
unlink( $surf_mask );

# transition zone at outer boundary. Blur border to have a smooth transition.
# The border will be at 0.5.

my $negative_mask = "${tmpdir}/negative_mask.mnc";
&run( 'minccalc', '-quiet', '-clobber', '-unsigned', '-short', 
      '-expression', 'A[0]<9.5', $grid, $negative_mask );
&run( 'mincchamfer', '-quiet', '-max_dist', 5, $negative_mask, $chamfer );

my $negative_mask_blur = "${tmpdir}/negative_mask_blur.mnc";
&quick_blur( $negative_mask, $negative_mask_blur );

&run( 'minccalc', '-quiet', '-clobber', '-unsigned', '-short', 
      '-expression', 'A[0]>9.5', $grid, $negative_mask );
my $mask_blur = "${tmpdir}/mask_blur.mnc";
&quick_blur( $negative_mask, $mask_blur );
unlink( $negative_mask );

my $pve = "${tmpdir}/pve_on_border.mnc";

&run( 'minccalc', '-quiet', '-clobber', '-unsigned', '-short', 
      '-expression', 'A[0]/(A[0]+A[1])',
      $mask_blur, $negative_mask_blur, $pve );

unlink( $mask_blur );
unlink( $negative_mask_blur );

# exterior chamfer map
&run( 'minccalc', '-quiet', '-clobber', '-unsigned', '-short', '-expression', 
      'if(A[0]<0.9){1}else{0}', $pve, $negative_mask );
&run( 'mincchamfer', '-quiet', '-max_dist', 5, $negative_mask, $chamfer );
unlink( $negative_mask );

# Combine into final grid file.

my $grid_tmp = "${tmpdir}/grid_tmp.mnc";
&run( 'minccalc', '-quiet', '-clobber', '-signed', '-short', '-expression', 
      'if(A[1]>0.1&&A[1]<0.9){9+2*A[1]}else{if(A[1]<=0.1){A[0]}else{11+A[2]}}',
      $grid, $pve, $chamfer, $grid_tmp );
&run( 'mv', '-f', $grid_tmp, $grid );

unlink( $pve );
unlink( $chamfer );

&run( 'laplacian_thickness', '-like', $labels, '-potential_only',
      '-volume-double', '-from_grid', $grid, 'none', 'none',
      '-convergence', '1e-8', '-max_iterations', '500', '-outer_value', '16.0',
      '-inner_value', '-5.0', '-mask_value', 5.0, $output );

unlink( $grid );


# the end


sub quick_blur {

  my $input = shift;
  my $output = shift;

  open BLUR, "> ${tmpdir}/blur.kernel";
  print BLUR "MNI Morphology Kernel File\n";
  print BLUR "Kernel_Type = Normal_Kernel;\n";
  print BLUR "Kernel =\n";
  print BLUR "-1.0  0.0  0.0  0.0  0.0  0.125\n";
  print BLUR " 1.0  0.0  0.0  0.0  0.0  0.125\n";
  print BLUR " 0.0 -1.0  0.0  0.0  0.0  0.125\n";
  print BLUR " 0.0  1.0  0.0  0.0  0.0  0.125\n";
  print BLUR " 0.0  0.0 -1.0  0.0  0.0  0.125\n";
  print BLUR " 0.0  0.0  1.0  0.0  0.0  0.125\n";
  print BLUR " 0.0  0.0  0.0  0.0  0.0  0.250;\n";

  &run( 'mincmorph', '-clobber', '-convolve', '-kernel', "${tmpdir}/blur.kernel",
        $input, $output );
  unlink( "${tmpdir}/blur.kernel" );
}



sub run {

   print STDOUT "@_\n" if ${verbose};
   system(@_) == 0 or die;
}


