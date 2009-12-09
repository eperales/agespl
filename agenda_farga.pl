#! /usr/bin/perl

use WWW::Mechanize;
use DateTime;
use pQuery;
use Test::Deep::NoTest qw(eq_deeply);
use Mail::Sendmail qw(sendmail);

use warnings;
use strict;


##
#  Agafem els esdeveniments de d'aqui 15 dies i fins a un any

my $date            = DateTime->now->add(weeks => 2);
my $one_year_later  = $date->clone->add(years => 1);

my $domain = "http://lafarga.cat/";

my @events;
my $body = "
Propers esdeveniments de programari lliure anunciats a lafarga.cat:

";

while ( DateTime->compare($date, $one_year_later) <= 0 )
{
    my @formats = ('%d', '%m', '%Y');
    my ($day, $month, $year) = $date->strftime(@formats);

    ##
    #  Accedim a l'agenda del dia en questió

    my $url = "$domain/agenda/$year-$month-$day";

    print("Obtenint esdeveniments per a $url\n");

    my $mech = WWW::Mechanize->new();

    $mech->get($url);

    if ($mech->success())
    {
        ##
        #  Obtenim els esdeveniments del dia
        
        my @event_links = get_event_links($mech);

        if (scalar(@event_links) > 0)
        {
            print ("\tS'han trobat ", scalar(@event_links), " esdeveniments\n");
        }

        ##
        #  Per a cada esdeveniment, accedim a la seva pàgina per
        #  obtenir-ne les dades concretes

        foreach my $link (@event_links)
        {
            my $event = get_event($domain, $link);

            ##
            #  Afegim l'esdeveniment a la llista, si no el teniem

            my $trobat = 0;
            my $i = 0;
            while (!$trobat and $i< scalar(@events))
            {
                $trobat = $trobat || eq_deeply($events[$i], $event);
                $i++;
            }

            push(@events, $event) if !$trobat;
        }

        ##
        #  Avançem el dia

        $date->add(days => 1);
    }


}

if (scalar(@events) > 0)
{

    $body .= compose_mail(@events);
    send_mail($body);
}
else
{
    print("Cap esdeveniment a la vista. No s'ha enviat cap correu\n");
    exit;
}


##
#  get_event_liks
#  Donat un objecte Mechanize que conté una pàgina de l'agenda de
#  lafarga, cerca tots els enllaços que siguin de tipus esdeveniment
#  
#    params: objecte Mechanize
#    return: array d'enllaços


sub get_event_links
{
    my ($mech) = @_;
    ##
    #  Agafem tots els enllaços que siguin de l'agenda

    my @agenda_links = $mech->find_all_links(url_regex => qr/agenda/i);
    my $count = @agenda_links;

    ##
    #  Ens quedem amb els que són esdeveniments

    my @event_links = @agenda_links[8..$count-1];

    return @event_links;
}


##
#  get_event($link)
#  Donada una url d'un esdevenimet de la farga, retrona les seves
#  dades
#
#  params: una url d'un esdeveniment de lafarga
#  return: hash amb les dades de l'esdeveniment

sub get_event
{
    my ($domain, $link) = @_;

    my $url = $domain.$link->url;

    my $dom = pQuery($url);

    my $title    = $dom->find('.content-bottom h2')->text();
    my $date     = $dom->find('.field-field-esdeveniment-data')->text();
    my $location = $dom->find('.field-field-ubicacio')->text();
    #my @desc     = $dom->find('.content-bottom .content p');

    #my $description;
    #foreach my $desc (@desc)
    #{
    #    $description .= $desc->text()."\n";
    #}

    my $event = {
        title       => $title . "\n" . '=' x length($title),
        date        => $date,
        location    => $location,
        url         => $url,
    #    description => $description,
    };

    return $event;
}

##
#  compose_mail
#  Donada una llista d'esdeveniments, construeix el cos del missatge
#  que s'enviarà a la llista de caliu
#
#  params: array d'esdeveniments
#  return: string - cos del missatge que s'ha d'enviar

sub compose_mail
{
    my (@events) = @_;

    my $body = '';

    foreach my $event_ref (@events)
    {
        my %event = %$event_ref;
        $body .= join("\n", @event{ qw( title date location url )} );
        $body .= "\n\n";
    }

    return $body;
}

##
#  send_mail
#  Envia un mail a la llista d'esdeveniments
#
#  params: string - cos del missatge
#  return: void

sub send_mail
{
    my ($body) = @_;

    my %mail = (
        From    => 'esdeveniments@cpl.upc.edu',
        To      => 'esdeveniments@cpl.upc.edu',
        Subject => 'Propers esdeveniments de Programari Lliure',
        Message => $body,
    );

    sendmail(%mail) or die $Mail::Sendmail::error;

    print "Missatge enviat correctament: \n", $Mail::Sendmail::log, "\n";
}

=head1 AUTHOR

Eva Perales Laguna

=head1 COPYRIGHT

Copyright (c) 2009. Eva Perales Laguna.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

See http://www.perl.com/perl/misc/Artistic.html

=cut

