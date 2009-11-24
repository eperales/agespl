#! /usr/bin/perl

use WWW::Mechanize;
use DateTime;
use Date::Manip;

use pQuery;

use Data::Dumper;

use warnings;
use strict;


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
	my ($link) = @_;

	my $dom = pQuery($link->url);

	my $title    = $dom->find('.content-bottom h2')->text();
	my $date     = $dom->find('.field-field-esdeveniment-data')->text();
	my $location = $dom->find('.field-field-ubicacio')->text();
	my @desc     = $dom->find('.content-bottom .content p');

	my %event = (
		title       => $title,
		date        => $date,
		location    => $location,
		description => @desc,
	);

	return %event;
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

	my $body = "
		Propers esdevenimetns de cultura i programari lliure anunciats
		a lafarga.cat:

	";
	foreach my $event (@events)
	{
		
	}
}
##
#  Agafem els esdeveniments de d'aqui 15 dies i fins a un any

my $date            = DateCalc('today', '+ 2 weeks');
my $one_year_later  = DateCalc('today', '+ 1 year');

my $domain = "http://lafarga.cat/";

my @events;
while ($date <= $one_year_later)
{
	my @formats = ('%d', '%m', '%Y');
	my ($day, $month, $year) = UnixDate($date, @formats);

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

		print(Dumper(@event_links));
		die;

		##
		#  Per a cada esdeveniment, accedim a la seva pàgina per
		#  obtenir-ne les dades concretes

		foreach my $link (@event_links)
		{
			my %event = get_event($domain.$link);			
			push(@events, %event);
		}

		##
		#  Avançem el dia

		$date = DateCalc($date, '+ 1 day');
	}

	compose_mail(@events);
	send_mail();
}


