#!/usr/bin/perl

use strict;
use warnings;
use RT;
use Email::MessageID;
use RT::Handle;

use Test::More tests => 11;
use_ok('RT::Interface::Email::Filter::CheckMessageId');

RT::Init();
my $initial_message_id = Email::MessageID->new->in_brackets;

sub parse_message {
    my ($msg) = @_;
}

diag("Send new message with In-Reply-To") if $ENV{'TEST_VERBOSE'};
{
my $text = <<END;
Subject: test
From: root\@localhost
Message-Id: <1360255715.4E360.19656\@localhost.localdomain>
In-Reply-To: $initial_message_id

test
END
    my $Ticket = RT::Ticket->new( $RT::SystemUser );
    my $parser = RT::EmailParser->new();
    $parser->SmartParseMIMEEntityFromScalar(
        Message => $text,
        Decode => 0,
        Exact => 1,
    );
    ok(my $Message = $parser->Entity, "can get message");
    RT::Interface::Email::Filter::CheckMessageId::ApplyBeforeDecode(
        Message       => $Message,
        RawMessageRef => \$text,
    );
    unlike  ($Message->head->get('Subject'), qr/\[.*\]/,
        'Subject contain ticket number');
}

my $test_ticket_id;

diag("Create a new ticket") if $ENV{'TEST_VERBOSE'};
{
    my $text = <<END;
Subject: test
From: root\@localhost
Message-Id: $initial_message_id

test
END

    my $Ticket = RT::Ticket->new( $RT::SystemUser);
    my $parser = RT::EmailParser->new();
    $parser->SmartParseMIMEEntityFromScalar(
        Message => $text,
        Decode => 0,
        Exact => 1,
    ); 
    my $Message = $parser->Entity;
    my ($id) = $Ticket->Create(
        Queue => 1,
        Subject => $Message->head->get('Subject'),
        Requestor => [ $RT::SystemUser->id ],
        Cc => [],
        MIMEObj => $Message,
    );    
    ok($id, "created ticket");
    my $obj = RT::Ticket->new( $RT::SystemUser );
    $obj->Load( $id );
    is($obj->id, $id, "loaded ticket $id");
    $test_ticket_id = $id;
}

diag("Send new message with In-Reply-To") if $ENV{'TEST_VERBOSE'};
{
my $text = <<END;
Subject: test
From: root\@localhost
Message-Id: <1360255715.4E360.19656\@localhost.localdomain>
In-Reply-To: $initial_message_id

test
END
    my $Ticket = RT::Ticket->new( $RT::SystemUser );
    my $parser = RT::EmailParser->new();
    $parser->SmartParseMIMEEntityFromScalar(
        Message => $text,
        Decode => 0,
        Exact => 1,
    );
    ok(my $Message = $parser->Entity, "can get message");
    RT::Interface::Email::Filter::CheckMessageId::ApplyBeforeDecode(
        Message       => $Message,
        RawMessageRef => \$text,
    );
    like  ($Message->head->get('Subject'), qr/$test_ticket_id/,
        'Subject contain ticket number');
}

diag("Send new message with References") if $ENV{'TEST_VERBOSE'};
{
my $text = <<END;
Subject: test
From: root\@localhost
Message-Id: <1360255715.4E360.19656\@localhost.localdomain>
References: $initial_message_id

test
END
    my $Ticket = RT::Ticket->new( $RT::SystemUser );
    my $parser = RT::EmailParser->new();
    $parser->SmartParseMIMEEntityFromScalar(
        Message => $text,
        Decode => 0,
        Exact => 1,
    );
    ok(my $Message = $parser->Entity, "can get message");
    RT::Interface::Email::Filter::CheckMessageId::ApplyBeforeDecode(
        Message       => $Message,
        RawMessageRef => \$text,
        CurrentUser   => $RT::SystemUser,
        Action        => 'correspond',
        Queue         => 1,
    );
    like  ($Message->head->get('Subject'), qr/$test_ticket_id\]/,
        'Subject contain ticket number');
}

diag("Send ticket id in subject") if $ENV{'TEST_VERBOSE'};
{
my $rtname = RT->Config->Get('rtname');
my $text = <<END;
Subject: test [$rtname #32]
From: root\@localhost
Message-Id: <1360255715.4E360.19656\@localhost.localdomain>
In-Reply-To: $initial_message_id

test
END
    my $Ticket = RT::Ticket->new( $RT::SystemUser );
    my $parser = RT::EmailParser->new();
    $parser->SmartParseMIMEEntityFromScalar(
        Message => $text,
        Decode => 0,
        Exact => 1,
    );
    ok(my $Message = $parser->Entity, "can get message");
    RT::Interface::Email::Filter::CheckMessageId::ApplyBeforeDecode(
        Message       => $Message,
        RawMessageRef => \$text,
    );
    unlike  ($Message->head->get('Subject'), qr/$test_ticket_id\]/,
        'Subject contain ticket number');
}

1;
