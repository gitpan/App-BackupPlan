# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl BackupPlan.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;
use Time::Local;

use Test::More tests => 17; 
BEGIN 
{ use_ok('App::BackupPlan')}; #test 1


#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $configFile = 'TestData/testPlan.xml';
my $logFile = 'TestData/log4perl.conf';
my @planArgs = ($configFile, $logFile);
my $plan = new_ok 'App::BackupPlan' => \@planArgs; #test2

my $parser = new XML::DOM::Parser;
my $doc = $parser->parsefile ($configFile) or die "Could not parse $configFile";
my ($defaultPolicy,%raw_policies) = App::BackupPlan::getPolicies($doc);
isa_ok($defaultPolicy,'App::BackupPlan::Policy'); #test 3
is(3, $defaultPolicy->{maxFiles},'policy default max number of files'); #test4
cmp_ok('1m', 'eq', $defaultPolicy->{frequency},'policy default frequency'); #test5
is(1,keys %raw_policies, 'expected number of policies'); #test6
ok(defined($raw_policies{test}), 'policy test is present'); #test 7

#time trasformation tests
my $time = timelocal(0,0,0,15,9,1963);
my $Ts = App::BackupPlan::formatTimeSpan($time);
cmp_ok('19631015','eq',$Ts,'time formatting test'); #test 8
#add 7 days
my $then = App::BackupPlan::addTimeSpan($time,'7d');
my $thenTs = App::BackupPlan::formatTimeSpan($then);
cmp_ok('19631022','eq',$thenTs,'add seven days'); #test 9		
#add 2 months
$then = App::BackupPlan::addTimeSpan($time,'2m');
$thenTs = App::BackupPlan::formatTimeSpan($then);		
cmp_ok('19631215','eq',$thenTs,'add two months'); #test 10
#add 1 year
$then = App::BackupPlan::addTimeSpan($time,'1y');
$thenTs = App::BackupPlan::formatTimeSpan($then);		
cmp_ok('19641015','eq',$thenTs,'add one year'); #test 11
#subtracting 7 days
$then = App::BackupPlan::subTimeSpan($time,'7d');
$thenTs = App::BackupPlan::formatTimeSpan($then);		
cmp_ok('19631008','eq',$thenTs,'subtracting seven days'); #test 12
#Subtracting 2 months
$then = App::BackupPlan::subTimeSpan($time,'2m');
$thenTs = App::BackupPlan::formatTimeSpan($then);		
cmp_ok('19630815','eq',$thenTs,'subtracting two months'); #test 13
#Subtracting 1 year
$then = App::BackupPlan::subTimeSpan($time,'1y');
$thenTs = App::BackupPlan::formatTimeSpan($then);		
cmp_ok('19621015','eq',$thenTs,'subtracting one year'); #test 14

#getFiles test
my $policy = $raw_policies{'test'};
my $sd = $policy->getSourceDir;
my $pr = $policy->getPrefix;
my %files = App::BackupPlan::getFiles($sd,$pr);
my $nc = keys %files;
cmp_ok(0,'lt',$nc,'number of files in source directory'); #test 15

#get environment
App::BackupPlan::getEnvironment();

#tar test
if ($App::BackupPlan::TAR eq 'system') {
	my $out = $policy->tar(App::BackupPlan::formatTimeSpan(time),$App::BackupPlan::HAS_EXCLUDE_TAG);
	unlike($out, qr/Error/, 'tar does not produce an Error'); #test 16
	like($out, qr/system/,'system tar'); #test 17
	
}
else { #perl tar test
	my $out = $policy->perlTar(App::BackupPlan::formatTimeSpan(time));
	unlike($out, qr/Error/, 'tar does not produce an Error'); #test 16
	like($out, qr/perl/,'perl tar'); #test 17
	
}


