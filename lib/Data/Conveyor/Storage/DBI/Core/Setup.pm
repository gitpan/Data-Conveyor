package Data::Conveyor::Storage::DBI::Core::Setup;

# Utility storage methods encapsulating statements that all or most
# applications based on Data-Conveyor are going to need. They presume a
# certain database layout, so if you use these conventions, these methods will
# work for you. If not, they won't.


use strict;
use warnings;
use DBI ':sql_types';

our $VERSION = '0.07';

sub add_lookup_items {
    my ($self, $table_name, $table_prefix, @items) = @_;

    $self->log->info('add_lookup_items [%s]', $table_name);

    # normalize the table name
    $table_name = '<P>_' . $table_name unless $table_name =~ /^<P>_/;

    # find the new items by removing the existing ones from the list given to
    # us.

    my %insert = map { $_ => 1 } @items;

    my $item;
    my $sth = $self->prepare("
        SELECT ${table_prefix}_code FROM $table_name
    ");
    $sth->execute;
    $sth->bind_columns(\$item);
    while ($sth->fetch) {
        $self->log->debug('existing [%s] lookup item [%s]',
            $table_name, $item);
        delete $insert{$item};
    }
    $sth->finish;

    $sth = $self->prepare("
        INSERT INTO $table_name (
            ${table_prefix}_id,
            ${table_prefix}_code,
            ${table_prefix}_create_user,
            ${table_prefix}_create_date
        ) VALUES (
            <NEXTVAL>(<P>_id_seq),
            :item,
            <USER>,
            <NOW>
        )
    ");

    for my $new_item (sort keys %insert) {
        $self->log->info('inserting [%s] lookup item [%s]',
            $table_name, $new_item);
        $sth->bind_param(':item', $new_item, SQL_VARCHAR);
        $sth->execute;
    }

    $sth->finish;
}


sub add_ticket_types {
    my ($self, @ticket_types) = @_;
    $self->add_lookup_items('request_types', 'ret', @ticket_types);
}


sub add_origins {
    my ($self, @origins) = @_;
    $self->add_lookup_items('origins', 'ori', @origins);
}


sub prime {
    my $self = shift;
    $self->add_ticket_types($self->delegate->TT);
    $self->add_origins($self->delegate->OR);
}


1;
