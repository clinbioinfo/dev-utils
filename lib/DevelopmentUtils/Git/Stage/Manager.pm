package DevelopmentUtils::Git::Stage::Manager;

use Moose;
use Cwd;
use Data::Dumper;
use File::Path;
use FindBin;
use File::Slurp;
use Term::ANSIColor;
use JSON::Parse 'json_file_to_perl';

use DevelopmentUtils::Logger;
use DevelopmentUtils::Config::Manager;

use constant TRUE  => 1;
use constant FALSE => 0;

use constant DEFAULT_TEST_MODE => TRUE;

my $login =  getlogin || getpwuid($<) || "sundaramj";

use constant DEFAULT_OUTDIR => '/tmp/' . $login . '/' . File::Basename::basename($0) . '/' . time();

use constant DEFAULT_INDIR => File::Spec->rel2abs(cwd());

use constant DEFAULT_JIRA_URL => '';

## Singleton support
my $instance;

has 'test_mode' => (
    is       => 'rw',
    isa      => 'Bool',
    writer   => 'setTestMode',
    reader   => 'getTestMode',
    required => FALSE,
    default  => DEFAULT_TEST_MODE
    );

has 'config_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setConfigfile',
    reader   => 'getConfigfile',
    required => FALSE,
    );

has 'outdir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setOutdir',
    reader   => 'getOutdir',
    required => FALSE,
    default  => DEFAULT_OUTDIR
    );

has 'indir' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setIndir',
    reader   => 'getIndir',
    required => FALSE,
    default  => DEFAULT_INDIR
    );

has 'commit_asset_list_file' => (
    is       => 'rw',
    isa      => 'Str',
    writer   => 'setCommitAssetListFile',
    reader   => 'getCommitAssetListFile',
    required => FALSE
    );

sub getInstance {

    if (!defined($instance)){

        $instance = new DevelopmentUtils::Git::Stage::Manager(@_);

        if (!defined($instance)){

            confess "Could not instantiate DevelopmentUtils::Git::Stage::Manager";
        }
    }
    return $instance;
}

sub BUILD {

    my $self = shift;

    $self->_initLogger(@_);

    $self->_initConfigManager(@_);

    $self->{_modified_staged_file_list} = [];
    $self->{_modified_staged_file_ctr} = 0;

    $self->{_deleted_staged_file_list} = [];
    $self->{_deleted_staged_file_ctr} = 0;

    $self->{_modified_not_staged_file_list} = [];
    $self->{_modified_not_staged_file_ctr} = 0;

    $self->{_deleted_not_staged_file_list} = [];
    $self->{_deleted_not_staged_file_ctr} = 0;
    
    $self->{_untracked_file_list} = [];
    $self->{_untracked_file_ctr} = 0;

    $self->{_final_deleted_not_staged_file_list} = [];
    $self->{_final_deleted_not_staged_file_ctr} = 0;

    $self->{_final_modified_not_staged_file_list} = [];
    $self->{_final_modified_not_staged_file_ctr} = 0;

    $self->{_final_untracked_file_list} = [];
    $self->{_final_untracked_file_ctr} = 0;

    $self->{_confirmed_asset_file_ctr} = 0;
    $self->{_confirmed_asset_file_list} = [];

    $self->{_logger}->info("Instantiated ". __PACKAGE__);
}

sub _initLogger {

    my $self = shift;

    my $logger = Log::Log4perl->get_logger(__PACKAGE__);

    if (!defined($logger)){
        confess "logger was not defined";
    }

    $self->{_logger} = $logger;
}

sub _initConfigManager {

    my $self = shift;

    my $manager = DevelopmentUtils::Config::Manager::getInstance(@_);
    if (!defined($manager)){
        $self->{_logger}->logconfess("Could not instantiate DevelopmentUtils::Config::Manager");
    }

    $self->{_config_manager} = $manager;
}

sub getAssetListContent {


    my $self = shift;

    return $self->_get_asset_list_content(@_);
}

sub _get_asset_list_content {

    my $self = shift;

    my $asset_file = $self->getCommitAssetListFile();

    if (!defined($asset_file)){
    
        $self->{_logger}->info("asset_file was not defined");
    
        $asset_file = $self->getOutdir() . '/asset-list-file.txt';

        $self->setCommitAssetListFile($asset_file);

        $self->_derive_asset_list_file_via_status($asset_file);
    }

    if (!-e $asset_file){

        $self->{_logger}->info("asset list file '$asset_file' does not exist");

        $self->_derive_asset_list_file_via_status($asset_file);
    }

    $self->_parse_asset_list_file($asset_file);

    if ($self->{_confirmed_asset_file_ctr} > 0){
        return join(' ', @{$self->{_confirmed_asset_file_list}});
    }
}

sub _parse_asset_list_file {

    my $self = shift;
    my ($asset_file) = @_;

    my @content = read_file($asset_file);

    my $asset_content_list;

    my $found_modified_not_staged_section = FALSE;
    my $found_modified_staged_section = FALSE;
    my $found_untracked_files_section = FALSE;    
    my $found_the_end = FALSE;

    foreach my $line (@content){

        chomp $line;

        if ($line =~ /^\s*$/){
            next;
        }

        if ($line =~ /^\s*\(/){
            $self->{_logger}->info("Ignoring this line '$line'");
            next;
        }
        elsif ($line =~ m|^Changes to be committed:|){

            print "Found changes (staged) to be committed\n";
        
            $found_modified_staged_section = TRUE;
            
            $found_modified_not_staged_section = TRUE;

            $found_untracked_files_section = FALSE;        

            next;
        }
        elsif ($line =~ m|^Changes not staged for commit:|){

            print "Found changes not staged for commit\n";
        
            $found_modified_not_staged_section = TRUE;

            $found_modified_staged_section = FALSE;

            $found_untracked_files_section = FALSE;        

            next;
        }
        elsif ($line =~ m|^Untracked files:|){
        
            print "Found untracked files section\n";

            $found_untracked_files_section = TRUE;
            
            $found_modified_staged_section = FALSE;

            $found_modified_not_staged_section = FALSE;

            next;
        }
        elsif ($line =~ m|no changes added to commit|){

            print "Found end section\n";

            $found_the_end = TRUE;

            $found_untracked_files_section = FALSE;
            
            $found_modified_staged_section = FALSE;

            $found_modified_not_staged_section = FALSE;
        } 
        else {

            if ($found_modified_staged_section){

                if ($line =~ m|^\s+modified:\s+(\S+)\s*$|){

                    my $file = $1;

                    if (!-e $file){
                        $self->{_logger}->logconfess("modified staged file '$file' does not exist");
                    }

                    push(@{$self->{_modified_staged_file_list}}, $file);

                    $self->{_modified_staged_file_ctr}++;                
                }
                elsif ($line =~ m|^\s+deleted:\s+(\S+)\s*$|){

                    my $file = $1;

                    push(@{$self->{_deleted_staged_file_list}}, $file);

                    $self->{_deleted_staged_file_ctr}++;                

                }
                else {
                    $self->{_logger}->logconfess("Unexpected line '$line'");
                }

                next;
            }
            elsif ($found_modified_not_staged_section){

                if ($line =~ m|^\s+modified:\s+(\S+)\s*$|){

                    my $file = $1;

                    if (!-e $file){
                        $self->{_logger}->logconfess("modified, not staged file '$file' does not exist");
                    }

                    push(@{$self->{_modified_not_staged_file_list}}, $file);

                    $self->{_modified_not_staged_file_ctr}++;                
                }
                elsif ($line =~ m|^\s+deleted:\s+(\S+)\s*$|){

                    my $file = $1;

                    push(@{$self->{_deleted_not_staged_file_list}}, $file);

                    $self->{_deleted_not_staged_file_ctr}++;                

                }
                else {
                    $self->{_logger}->logconfess("Unexpected line '$line'");
                }

                next;
            }
            elsif ($found_untracked_files_section){

                if ($line =~ m|^\s+(\S+)\s*$|){

                    my $untracked_file = $1;

                    if (!-e $untracked_file){
                        $self->{_logger}->logconfess("untracked file '$untracked_file' does not exist");
                    }

                    push(@{$self->{_untracked_file_list}}, $untracked_file);

                    $self->{_untracked_file_ctr}++;
                }
                elsif ($line eq 'nothing added to commit but untracked files present (use "git add" to track)'){
                    next;
                }
                else {
                    $self->{_logger}->logconfess("Unexpected line '$line'");
                }
            }
        }
    }

    if (($self->{_modified_staged_file_ctr} == 0)  && 
        ($self->{_modified_not_staged_file_ctr} == 0)  && 
        ($self->{_deleted_staged_file_ctr} == 0)  && 
        ($self->{_deleted_not_staged_file_ctr} == 0)  && 
        ($self->{_untracked_file_ctr} == 0)){
        $self->{_logger}->logconfess("Did not find any modified, deleted- nor any untracked files");
    }
    else {

        $self->_prompt_user_about_files();

        ##---------------------------------------
        ## modified files
        ##---------------------------------------
        if ((exists $self->{_modified_not_staged_file_ctr})  && 
            ($self->{_modified_not_staged_file_ctr} > 0)){

            if ((exists $self->{_final_modified_not_staged_file_ctr})  && 
                ($self->{_final_modified_not_staged_file_ctr} > 0)){

                $self->_stage_modified_not_staged_files();
            }
            else {
                
                printYellow("User does not want to stage '$self->{_modified_not_staged_file_ctr}' modified, but not staged files");
                
                $self->{_logger}->warn("User does not want to stage any of the '$self->{_modified_not_staged_file_ctr}' modified, not staged files");
            }
        }

        ##---------------------------------------
        ## deleted files
        ##---------------------------------------
        if ((exists $self->{_deleted_not_staged_file_ctr}) &&
            ($self->{_deleted_not_staged_file_ctr} > 0)){

            if ((exists $self->{_final_deleted_not_staged_file_ctr}) &&
                ($self->{_final_deleted_not_staged_file_ctr} > 0)){

                $self->_stage_deleted_not_staged_files();
            }
            else {
                
                printYellow("User does not want to stage '$self->{_deleted_not_staged_file_ctr}' deleted, not staged files");
                
                $self->{_logger}->warn("User does not want to stage any of the '$self->{_deleted_not_staged_file_ctr}' deleted, not staged files");
            }
        }

        ##---------------------------------------
        ## untracked files
        ##---------------------------------------
        if ((exists $self->{_untracked_file_ctr})  && 
            ($self->{_untracked_file_ctr} > 0)){

            if ((exists $self->{_final_untracked_file_ctr})  && 
                ($self->{_final_untracked_file_ctr} > 0)){

                $self->_stage_untracked_files();            
            }
            else {
                printYellow("User does not want to stage any of the '$self->{_untracked_file_ctr}' untracked files");
                    
                $self->{_logger}->warn("User does not want to stage any of the '$self->{_untracked_file_ctr}' untracked files");
            }
        }
            

        if ((exists $self->{_modified_staged_file_ctr})  &&             
            ($self->{_modified_staged_file_ctr} > 0)){

            ## Have modified files that are already staged.
            $self->_add_modified_files_to_confirmed_asset_list();
        }
        else {
            $self->{_logger}->info("No modified files to be added to the confirmed assets list");
        }

        if ((exists $self->{_deleted_staged_file_ctr})  &&             
            ($self->{_deleted_staged_file_ctr} > 0)){

            ## Have deleted files that are already staged.
            $self->_add_deleted_files_to_confirmed_asset_list();
        }
        else {
            $self->{_logger}->info("No deleted files to be added to the confirmed assets list");
        }
    }
}

sub _add_modified_files_to_confirmed_asset_list {

    my $self = shift;

    if ((exists $self->{_modified_staged_file_list}) &&
        (scalar(@{$self->{_modified_staged_file_list}}) > 0)){

        my $file_ctr = 0;

        foreach my $file (@{$self->{_modified_staged_file_list}}){
        
            $file_ctr++;

            push(@{$self->{_confirmed_asset_file_list}}, $file);
        
            $self->{_confirmed_asset_file_ctr}++;
        }

        $self->{_logger}->info("Added '$file_ctr' modified (already staged) files to the confirmed assets list");
    }
    else {
        $$self->{_logger}->logconfess("Why are we attempting to add modified (already staged) files to the confirmed assets list?");
    }
}

sub _add_deleted_files_to_confirmed_asset_list {

    my $self = shift;

    if ((exists $self->{_deleted_staged_file_list}) &&
        (scalar(@{$self->{_deleted_staged_file_list}}) > 0)){

        my $file_ctr = 0;

        foreach my $file (@{$self->{_deleted_staged_file_list}}){
        
            $file_ctr++;

            push(@{$self->{_confirmed_asset_file_list}}, $file);
        
            $self->{_confirmed_asset_file_ctr}++;
        }

        $self->{_logger}->info("Added '$file_ctr' deleted (already staged) files to the confirmed assets list");
    }
    else {
        $$self->{_logger}->logconfess("Why are we attempting to add deleted (already staged) files to the confirmed assets list?");
    }
}

sub _prompt_user_about_files {

    my $self = shift;
    
    $self->_prompt_user_about_modified_staged_files();

    $self->_prompt_user_about_modified_not_staged_files();

    $self->_prompt_user_about_deleted_staged_files();

    $self->_prompt_user_about_deleted_not_staged_files();

    $self->_prompt_user_about_untracked_files();
}

sub _prompt_user_about_modified_staged_files {

    my $self = shift;
    
    if ($self->{_modified_staged_file_ctr} > 0){
        
        printYellow("\nFound the following '$self->{_modified_staged_file_ctr}' modified, staged files:");
        
        print join("\n", @{$self->{_modified_staged_file_list}}) . "\n";

        #$self->_ask_user_about_modified_staged_files();
    }
    else {
        $self->{_logger}->info("Did not find any modified, staged files");
    }
}

sub _prompt_user_about_modified_not_staged_files {

    my $self = shift;

    if ($self->{_modified_not_staged_file_ctr} > 0){
        
        printYellow("\nFound the following '$self->{_modified_not_staged_file_ctr}' modified, but not staged files:");
        
        print join("\n", @{$self->{_modified_not_staged_file_list}}) . "\n";

        $self->_ask_user_about_modified_not_staged_files();
    }
    else {
        $self->{_logger}->info("Did not find any modified but not staged files");
    }
}

sub _prompt_user_about_deleted_staged_files {

    my $self = shift;
    
    if ($self->{_deleted_staged_file_ctr} > 0){
        
        printYellow("\nFound the following '$self->{_deleted_staged_file_ctr}' deleted, staged files:");
        
        print join("\n", @{$self->{_deleted_staged_file_list}}) . "\n";

        # $self->_ask_user_about_deleted_staged_files();
    }
    else {
        $self->{_logger}->info("Did not find any deleted, staged files");
    }
}

sub _prompt_user_about_deleted_not_staged_files {

    my $self = shift;

    if ($self->{_deleted_not_staged_file_ctr} > 0){
        
        printYellow("\nFound the following '$self->{_deleted_not_staged_file_ctr}' deleted, but not staged files:");
        
        print join("\n", @{$self->{_deleted_not_staged_file_list}}) . "\n";

        $self->_ask_user_about_deleted_not_staged_files();
    }
    else {
        $self->{_logger}->info("Did not find any deleted but not staged files");
    }
}

sub _prompt_user_about_untracked_files {

    my $self = shift;
    
    if ($self->{_untracked_file_ctr} > 0){

        printYellow("\nFound the following '$self->{_untracked_file_ctr}' untracked files:");
        
        print join("\n", @{$self->{_untracked_file_list}}) . "\n";

        $self->_ask_user_about_untracked_files();
    }
    else {
        $self->{_logger}->info("Did not find any untracked files");
    }
}


# sub _stage_files {

#     my $self = shift;

#     if ((! exists $self->{_final_modified_not_staged_file_ctr}) && 
#         (! exists $self->{_final_deleted_not_staged_file_ctr}) && 
#         (! exists $self->{_final_untracked_file_ctr})){

#         printBoldRed("User does not have any files to be staged.");
        
#         exit(2);
#     }

#     if (($self->{_final_modified_not_staged_file_ctr} == 0) && 
#         ($self->{_final_deleted_not_staged_file_ctr} == 0) && 
#         ($self->{_final_untracked_file_ctr} == 0)){
        
#         printBoldRed("User does not have any files to be staged.");
        
#         exit(2);
#     }

#     if (exists $self->{_final_modified_not_staged_file_ctr}){

#         if ($self->{_final_modified_not_staged_file_ctr} > 0){

#             $self->_stage_modified_not_staged_files();
#         }
#         else {
            
#             printYellow("User does not want to stage any of the '$self->{_modified_not_staged_file_ctr}' modified, not staged files");
            
#             $self->{_logger}->warn("User does not want to stage any of the '$self->{_modified_not_staged_file_ctr}' modified, not staged files");
#         }
#     }
#     else {
#         $self->{_logger}->info("There are no modified, not staged files to be staged");
#     }

#     if (exists $self->{_final_deleted_not_staged_file_ctr}){

#         if ($self->{_final_deleted_not_staged_file_ctr} > 0){

#             $self->_stage_deleted_not_staged_files();
#         }
#         else {
            
#             printYellow("User does not want to stage any of the '$self->{_deleted_not_staged_file_ctr}' deleted, not staged files");
            
#             $self->{_logger}->warn("User does not want to stage any of the '$self->{_deleted_not_staged_file_ctr}' deleted, not staged files");
#         }
#     }
#     else {
#         $self->{_logger}->info("There are no deleted, not staged files to be staged");
#     }

#     if (exists $self->{_final_untracked_file_ctr}){

#         if ($self->{_final_untracked_file_ctr} > 0){
#             $self->_stage_untracked_files();
#         }
#         else {
        
#             printYellow("User does not want to stage any of the '$self->{_untracked_file_ctr}' untracked files");
                
#             $self->{_logger}->warn("User does not want to stage any of the '$self->{_untracked_file_ctr}' untracked files");
#         }
#     }
#     else {
#         $self->{_logger}->info("There are no untracked files to be staged");
#     }
# }


sub _ask_user_about_modified_not_staged_files {

    my $self = shift;

    print "\nLooks like there are '$self->{_modified_not_staged_file_ctr}' modified, not staged files to be committed to git.\n";
    printYellow("Please confirm which ones you'd like to stage.");

    my $file_ctr = 0;

    foreach my $file (sort @{$self->{_modified_not_staged_file_list}}){
    
        $file_ctr++;

        while (1) {

            print $file_ctr . ". " . $file . " [Y/n/q]";
            
            my $answer = <STDIN>;
            
            chomp $answer;
            
            $answer = uc($answer);

            if ((!defined($answer eq '')) || ($answer eq '')){
                $answer = 'Y';
            }
            
            if ($answer eq 'Y'){

                push(@{$self->{_final_modified_not_staged_file_list}}, $file);

                $self->{_final_modified_not_staged_file_ctr}++;

                $self->{_logger}->info("User wants to stage modified file '$file'");

                goto NEXT_MODIFIED_FILE;
            }
            elsif ($answer eq 'N'){
                
                $self->{_logger}->info("user did not want to stage modified file '$file'");

                goto NEXT_MODIFIED_FILE;
            }
            elsif ($answer eq 'Q'){

                printBoldRed("Umm, okay- bye");
                                
                $self->{_logger}->info("user asked to quit");
                
                exit(1);
            }
        }

        NEXT_MODIFIED_FILE: 
    }
}

sub _ask_user_about_deleted_not_staged_files {

    my $self = shift;

    print "\nLooks like there are '$self->{_deleted_not_staged_file_ctr}' deleted, not staged files to be staged to be committed to git.\n";
    printYellow("Please confirm which ones you'd like to stage.");

    my $file_ctr = 0;

    foreach my $file (sort @{$self->{_deleted_not_staged_file_list}}){
    
        $file_ctr++;

        while (1) {

            print $file_ctr . ". " . $file . " [Y/n/q]";
            
            my $answer = <STDIN>;
            
            chomp $answer;
            
            $answer = uc($answer);

            if ((!defined($answer eq '')) || ($answer eq '')){
                $answer = 'Y';
            }
            
            if ($answer eq 'Y'){

                push(@{$self->{_final_deleted_not_staged_file_list}}, $file);

                $self->{_final_deleted_not_staged_file_ctr}++;

                $self->{_logger}->info("User wants to stage delete file '$file'");

                goto NEXT_DELETED_FILE;
            }
            elsif ($answer eq 'N'){
                
                $self->{_logger}->info("user did not want to stage deleted file '$file'");

                goto NEXT_DELETED_FILE;
            }
            elsif ($answer eq 'Q'){

                printBoldRed("Umm, okay- bye");
                                
                $self->{_logger}->info("user asked to quit");
                
                exit(1);
            }
        }

        NEXT_DELETED_FILE: 
    }
}

sub _stage_modified_not_staged_files {

    my $self = shift;

    if ((exists $self->{_final_modified_not_staged_file_list}) &&
        (scalar(@{$self->{_final_modified_not_staged_file_list}}) > 0)){

        foreach my $file (@{$self->{_final_modified_not_staged_file_list}}){
        
            push(@{$self->{_confirmed_asset_file_list}}, $file);
        
            $self->{_confirmed_asset_file_ctr}++;
        }

        my $cmd = "git add " . join(' ', @{$self->{_final_modified_not_staged_file_list}});
        
        if ($self->getTestMode()){
            
            printYellow("Running in test mode - would have executed: $cmd");
            
            $self->{_logger}->info("Running in test mode - would have executed: $cmd");
        }
        else {
            $self->_execute_cmd($cmd);
        }
    }
    else {
        $$self->{_logger}->logconfess("Why are we attempting to stage modified files?");
    }
}

sub _stage_deleted_not_staged_files {

    my $self = shift;

    if ((exists $self->{_final_deleted_not_staged_file}) &&
        (scalar(@{$self->{_final_deleted_not_staged_file}}) > 0)){

        foreach my $file (@{$self->{_final_deleted_not_staged_file_list}}){
        
            push(@{$self->{_confirmed_asset_file_list}}, $file);
        
            $self->{_confirmed_asset_file_ctr}++;
        }

        my $cmd = "git add " . join(' ', @{$self->{_final_deleted_not_staged_file_list}});
        
        if ($self->getTestMode()){
            
            printYellow("Running in test mode - would have executed: $cmd");
            
            $self->{_logger}->info("Running in test mode - would have executed: $cmd");
        }
        else {
            $self->_execute_cmd($cmd);
        }
    }
    else {
        $$self->{_logger}->logconfess("Why are we attempting to stage deleted files?");
    }
}

sub _ask_user_about_untracked_files {

    my $self = shift;

    print "\nLooks like there are '$self->{_untracked_file_ctr}' untracked files to be staged to be committed to git.\n";
    printYellow("Please confirm which ones you'd like to stage.");

    my $file_ctr = 0;

    foreach my $untracked_file (sort @{$self->{_untracked_file_list}}){
    
        $file_ctr++;

        while (1) {

            print $file_ctr . ". " . $untracked_file . " [Y/n/q]";
            
            my $answer = <STDIN>;
            
            chomp $answer;
            
            $answer = uc($answer);
            
            if ($answer eq ''){
                $answer = 'Y';
            }

            if ($answer eq 'Y'){

                push(@{$self->{_final_untracked_file_list}}, $untracked_file);

                $self->{_final_untracked_file_ctr}++;

                $self->{_logger}->info("User wants to stage untracked file '$untracked_file'");

                goto NEXT_UNTRACKED_FILE;
            }
            elsif ($answer eq 'N'){
                
                $self->{_logger}->info("user did not want to stage untracked file '$untracked_file'");

                goto NEXT_UNTRACKED_FILE;
            }
            elsif ($answer eq 'Q'){
                            
                printBoldRed("Umm, okay- bye");

                $self->{_logger}->info("user asked to quit");
                
                exit(1);
            }
        }

        NEXT_UNTRACKED_FILE: 
    }
}

sub _stage_untracked_files {

    my $self = shift;

    if ((exists $self->{_final_untracked_file_list}) &&
        (scalar(@{$self->{_final_untracked_file_list}}) > 0)){

        foreach my $file (@{$self->{_final_untracked_file_list}}){
        
            push(@{$self->{_confirmed_asset_file_list}}, $file);
        
            $self->{_confirmed_asset_file_ctr}++;
        }

        my $cmd = "git add " . join(' ', @{$self->{_final_untracked_file_list}});

        if ($self->getTestMode()){
            
            printYellow("Running in test mode - would have executed '$cmd'");
            
            $self->{_logger}->info("Running in test mode - would have executed '$cmd'");
        }
        else {
            $self->_execute_cmd($cmd);
        }
    }
    else {
        $self->{_logger}->logconfess("Why are we attempting to stage untracked files?");
    }
}

sub _derive_asset_list_file_via_status {

    my $self = shift;
    my ($asset_file) = @_;

    my $cmd = "git status";

    my $results = $self->_execute_cmd($cmd);

    open (OUTFILE, ">$asset_file") || $self->{_logger}->logconfess("Could not open '$asset_file' in write mode : $!");
    
    foreach my $line (@{$results}){
        print OUTFILE $line . "\n";
    }

    close OUTFILE;

    $self->{_logger}->info("Wrote to '$asset_file'");
}

sub _execute_cmd {

    my $self = shift;
    my ($cmd) = @_;
    
    my @results;
 
    $self->{_logger}->info("About to execute '$cmd'");
    
    eval {
    	@results = qx($cmd);
    };

    if ($?){
    	$self->{_logger}->logconfess("Encountered some error while attempting to execute '$cmd' : $! $@");
    }


    chomp @results;

    return \@results;
}

sub printBoldRed {

    my ($msg) = @_;
    print color 'bold red';
    print $msg . "\n";
    print color 'reset';
}

sub printYellow {

    my ($msg) = @_;
    print color 'yellow';
    print $msg . "\n";
    print color 'reset';
}

sub printGreen {

    my ($msg) = @_;
    print color 'green';
    print $msg . "\n";
    print color 'reset';
}


no Moose;
__PACKAGE__->meta->make_immutable;

__END__


=head1 NAME

 DevelopmentUtils::Git::Stage::Manager
 

=head1 VERSION

 1.0

=head1 SYNOPSIS

 use DevelopmentUtils::Git::Stage::Manager;
 my $manager = DevelopmentUtils::Git::Stage::Manager::getInstance();
 my $asset_list_content = $manager->getAssetListContent();

=head1 AUTHOR

 Jaideep Sundaram

 Copyright Jaideep Sundaram

=head1 METHODS

=over 4

=cut
