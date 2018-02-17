#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

my @random_variable_realization;

my $basic_gnuplot_file_points =
"set style line 1 lc rgb \'#0060ad\'
set style line 2 lc rgb \'#dd181f\'
set xrange [-4:4]
set yrange [-4:4]
set ylabel \'B_2\'
set xlabel \'B_1\'
set terminal svg size 350,262 enhanced font \'Verdana,10\'
set output \'random_variable_realization.svg\' 
plot filename index 0 ls 1 notitle";
my $basic_gnuplot_file_trajectories = 
"set style line 1 lc rgb \'#0060ad\'
set terminal svg size 350,262 enhanced font \'Verdana,10\'
set output \'brown_movement.svg\' 
plot \\\n";


 # pocet nahodnych premennych pouzitich pri generovani normalneho rozdelenia
my $no_random_variables = 1000;
	# Lindeberg-Levy central limit theorem 
	# Using continuous uniform distribution
sub generate_normal_distribution 
{
	my ($sigma, $no_random_variables) = @_;

	my $sum = 0;

	my $range = sqrt(3*$sigma);

	foreach my $random_number (1..$no_random_variables) {
		my $generated_number = (rand() - 0.5) * 2 * $range;
		$sum += $generated_number;
	}

	my $mean = (1 / $no_random_variables) * $sum;
	return sqrt($no_random_variables)  * $mean;
}

sub test_normal_distribution 
{
	my ($sigma, @data) = @_;

	my $pos = 0;
	my $neg = 0;
	my $sigma1 = 0;
	my $sigma2 = 0;
	my $sigma3 = 0;

	my $no = $#data;

	print "no: $no\n";


	foreach my $num ( @data ) {
		if( $num > 0 ) {
			$pos++;
		} else {
			$neg++;
		}

		if( $num < sqrt($sigma) && $num > -sqrt($sigma)) {
			$sigma1++;
		}

		if( $num < 2*sqrt($sigma) && $num > -2*sqrt($sigma)) {
			$sigma2++;
		}
		if( $num < 3*sqrt($sigma) && $num > -3*sqrt($sigma)) {
			$sigma3++;
		}
	}

	print "Symetria: " . (1 - ( abs($pos - $neg) / $no )) . "%\n";
	print "68-95-99.7 ~ " . ($sigma1 / $no) * 100 . "-" . ($sigma2 / $no) * 100 . "-" . ($sigma3 / $no) * 100 . "%\n";
}

sub generate_brown_trajectory
{
	my ($no_time_steps, $length) = @_;

	my $delta_time = $length / $no_time_steps;

	my $time = 0;
	my $y = 0;

	my @data; push @data, [ 0, 0 ];

	foreach my $i (1..$no_time_steps) {
		$y += generate_normal_distribution($delta_time, $no_random_variables);
		$time += $delta_time;

		push @data, [ $time, $y ];
	}

	return \@data;
}

sub generate_brown_trajectories
{
	my ($no_trajectories, $no_time_steps, $length) = @_;

	my @trajectories;

	foreach (1..$no_trajectories) {
		push @trajectories, generate_brown_trajectory($no_time_steps, $length);
	}

	return \@trajectories;
}

sub process_trajectory
{
	my ($trajectory) = @_;

		# V case 1 je hodnota viac nez jedna a v case 2 je hodnota medzi 0 a 1;	
	if($trajectory->[1]->[1] > 1 && $trajectory->[2]->[1] > 0 && $trajectory->[2]->[1] < 1) {
		push @random_variable_realization, [ $trajectory->[1]->[1], $trajectory->[2]->[1] ];
		return 0;
	} else {
		return 1;
	}
}

sub generate_graph_brown_trajectories
{
	my ($no_trajectories, $no_time_steps, $length, $filename) = @_;	

	open (my $data_file, '>', "$filename.dat")
		or die "Cannot open $filename.dat";

	open (my $gnuplot_file, '>', "$filename.plg")
		or die "Cannot open $filename.plg";

	print $gnuplot_file $basic_gnuplot_file_trajectories;

	my $trajectories = generate_brown_trajectories($no_trajectories, $no_time_steps, $length);

	foreach my $i ( 0..$#{ $trajectories } ) {
		if(process_trajectory($trajectories->[$i])) {
			print $gnuplot_file "filename index $i with linespoints ls 1 notitle, \\\n";
		} else {
			print $gnuplot_file "filename index $i with linespoints ls 2 notitle, \\\n";
		}
		
		foreach my $coordinates ( @{ $trajectories->[$i] } ) {
			print $data_file "$coordinates->[0] $coordinates->[1]\n";
		}
		print $data_file "\n\n";
	}
}

sub generate_graph_random_variable_realization 
{
	my ($filename, @data) = @_;
	
	open (my $data_file, '>', "$filename.dat")
		or die "Cannot open $filename.dat";

	open (my $gnuplot_file, '>', "$filename.plg")
		or die "Cannot open $filename.plg";

	print $gnuplot_file $basic_gnuplot_file_points;

	foreach my $coordinates ( @data ) {
		print $data_file "$coordinates->[0] $coordinates->[1]\n";
	}
}

	# pocet vygenerovanych trajektorii
my $no_trajectories = 10000;
	# pocet casovych krokov
my $no_time_steps = 10;
	# dlzka trajektorii je rovnaka pre vytvorenie hodnot B1 a B2
my $length = $no_time_steps;


my $trajectories_filename = "trajectories";
my $random_variable_realization_filename = "random_variable_realization";

generate_graph_brown_trajectories($no_trajectories, $no_time_steps, $length, $trajectories_filename);
`gnuplot -e "filename='$trajectories_filename.dat'" $trajectories_filename.plg`;

	# pocet realizacii nahodnych premennych moze byt 0
if( @random_variable_realization ) {
	generate_graph_random_variable_realization($random_variable_realization_filename, @random_variable_realization);
	`gnuplot -e "filename='$random_variable_realization_filename.dat'" $random_variable_realization_filename.plg`;
}
