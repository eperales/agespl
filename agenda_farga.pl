#! /usr/bin/perl

use WWW::Mechanize;
use DateTime;
use Test::Deep::NoTest;

use pQuery;

use Data::Dumper;

use warnings;
use strict;


##
#  Agafem els esdeveniments de d'aqui 15 dies i fins a un any

my $date            = DateTime->now;
my $one_year_later  = $date->clone->add(months => 1);

my $domain = "http://lafarga.cat/";

my @events;
my $body = "
Propers esdeveniments de programari lliure anunciats a lafarga.cat:

\t";

while ( DateTime->compare($date, $one_year_later) <= 0 )
{
	my @formats = ('%d', '%m', '%Y');
	my ($day, $month, $year) = $date->strftime(@formats);

	##
	#  Accedim a l'agenda del dia en questió

	my $url = "$domain/agenda/$year-$month-$day";

	my $mech = WWW::Mechanize->new();

	$mech->get($url);

	if ($mech->success())
	{
		##
		#  Obtenim els esdeveniments del dia
		
		my @event_links = get_event_links($mech);


		##
		#  Per a cada esdeveniment, accedim a la seva pàgina per
		#  obtenir-ne les dades concretes

		foreach my $link (@event_links)
		{
			my $event = get_event($domain, $link);

			##
			#  Afegim l'esdeveniment a la llista, si no el teniem

			#unless eq_deeply($a, $b);
			push(@events, $event);
		}

		##
		#  Avançem el dia

		$date->add(days => 1);
	}

	$body .= compose_mail(@events);
#	send_mail();
}

print $body, "\n";

##
#  get_event_liks
#  Donat un objecte Mechanize que conté una pàgina de l'agenda de
#  lafarga, cerca tots els enllaços que siguin de tipus esdeveniment
#  
#	params: objecte Mechanize
#	return: array d'enllaços


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

	my $dom = pQuery($domain.$link->url);

	my $title    = $dom->find('.content-bottom h2')->text();
	my $date     = $dom->find('.field-field-esdeveniment-data')->text();
	my $location = $dom->find('.field-field-ubicacio')->text();
	my @desc     = $dom->find('.content-bottom .content p');

	my $description;
	foreach my $desc (@desc)
	{
		$description .= $desc->text()."\n";
	}

	my $event = {
		title       => $title,
		date        => $date,
		location    => $location,
		description => $description,
	};

	return $event;
}

##
#  compose_mail
#  Donada una llista d'esdeveniments, construeix el mail que s'enviarà
#  a la llista de caliu
#
#  params: array d'esdeveniments
#  return: string cos del missatge que s'ha d'enviar

sub compose_mail
{
	my (@events) = @_;

	my $body = '';

	foreach my $event (@events)
	{
		$body .= join("\n\t", values(%$event));
		$body .= "\n\n\t";
	}

	return $body;
}

