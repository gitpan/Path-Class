
use strict;
use Test::More;
use Path::Class;

plan tests => 60;
ok 1;

my $file = file('t', 'testfile');
ok $file;

{
  my $fh = $file->open('w');
  ok $fh;
  
  ok print $fh "Foo\n";
}

ok -e $file;

{
  my $fh = $file->open;
  is scalar <$fh>, "Foo\n";
}

{
  my $stat = $file->stat;
  ok $stat;
  cmp_ok $stat->mtime, '>', time() - 20;  # Modified within last 20 seconds

  $stat = $file->dir->stat;
  ok $stat;
}

1 while unlink $file;
ok not -e $file;


my $dir = dir('t', 'testdir');
ok $dir;

ok mkdir($dir, 0777);
ok -d $dir;

$file = $dir->file('foo.x');
$file->touch;
ok -e $file;

{
  my $dh = $dir->open;
  ok $dh;

  my @files = readdir $dh;
  is scalar @files, 3;
  ok scalar grep { $_ eq 'foo.x' } @files;
}

ok $dir->rmtree;
ok !-e $dir;

{
  $dir = dir('t', 'foo', 'bar');
  ok $dir->mkpath;
  ok -d $dir;
  
  $dir = $dir->parent;
  ok $dir->rmtree;
  ok !-e $dir;
}

{
  $dir = dir('t', 'foo');
  ok $dir->mkpath;
  ok $dir->subdir('dir')->mkpath;
  ok -d $dir->subdir('dir');
  
  ok $dir->file('file.x')->open('w');
  ok $dir->file('0')->open('w');
  my @contents;
  while (my $file = $dir->next) {
    push @contents, $file;
  }
  is scalar @contents, 5;

  my $joined = join ' ', map $_->basename, sort grep {-f $_} @contents;
  is $joined, '0 file.x';
  
  my ($subdir) = grep {$_ eq $dir->subdir('dir')} @contents;
  ok $subdir;
  is -d $subdir, 1;

  my ($file) = grep {$_ eq $dir->file('file.x')} @contents;
  ok $file;
  is -d $file, '';
  
  ok $dir->rmtree;
  ok !-e $dir;
}

{
  my $file = file('t', 'slurp');
  ok $file;
  
  my $fh = $file->open('w') or die "Can't create $file: $!";
  print $fh "Line1\nLine2\n";
  close $fh;
  ok -e $file;
  
  my $content = $file->slurp;
  is $content, "Line1\nLine2\n";
  
  my @content = $file->slurp;
  is_deeply \@content, ["Line1\n", "Line2\n"];

  @content = $file->slurp(chomp => 1);
  is_deeply \@content, ["Line1", "Line2"];

  $file->remove;
  ok not -e $file;
}

{
  # Make sure we can make an absolute/relative roundtrip
  my $cwd = dir();
  is $cwd, $cwd->absolute->relative, "from $cwd to ".$cwd->absolute." to ".$cwd->absolute->relative;
}

{
  # Test recursive iteration through the following structure:
  #     a
  #    / \
  #   b   c
  #  / \   \
  # d   e   f
  #    / \   \
  #   g   h   i
  (my $abe = dir(qw(a b e)))->mkpath;
  (my $acf = dir(qw(a c f)))->mkpath;
  file($acf, 'i')->touch;
  file($abe, 'h')->touch;
  file($abe, 'g')->touch;
  file('a', 'b', 'd')->touch;

  my $a = dir('a');

  # Make sure the children() method works ok
  my @children = sort map $_->as_foreign('Unix'), $a->children;
  is_deeply \@children, ['a/b', 'a/c'];
  
  {
    recurse_test( $a,
		  preorder => 1, depthfirst => 0,  # The default
		  precedence => [qw(a           a/b
				    a           a/c
				    a/b         a/b/e/h
				    a/b         a/c/f/i
				    a/c         a/b/e/h
				    a/c         a/c/f/i
				   )],
		);
  }

  {
    my $files = 
      recurse_test( $a,
		    preorder => 1, depthfirst => 1,
		    precedence => [qw(a           a/b
				      a           a/c
				      a/b         a/b/e/h
				      a/c         a/c/f/i
				     )],
		  );
    is_depthfirst($files);
  }

  {
    my $files = 
      recurse_test( $a,
		    preorder => 0, depthfirst => 1,
		    precedence => [qw(a/b         a
				      a/c         a
				      a/b/e/h     a/b
				      a/c/f/i     a/c
				     )],
		  );
    is_depthfirst($files);
  }
  

  $a->rmtree;

  sub is_depthfirst {
    my $files = shift;
    if ($files->{'a/b'} < $files->{'a/c'}) {
      cmp_ok $files->{'a/b/e'}, '<', $files->{'a/c'}, "Ensure depth-first search";
    } else {
      cmp_ok $files->{'a/c/f'}, '<', $files->{'a/b'}, "Ensure depth-first search";
    }
  }

  sub recurse_test {
    my ($dir, %args) = @_;
    my $precedence = delete $args{precedence};
    my ($i, %files) = (0);
    $a->recurse( callback => sub {$files{shift->as_foreign('Unix')->stringify} = ++$i},
		 %args );
    while (my ($pre, $post) = splice @$precedence, 0, 2) {
      cmp_ok $files{$pre}, '<', $files{$post}, "$pre should come before $post";
    }
    return \%files;
  }
}
