package WWW::UKTrains;

=head1 NAME

WWW::UKTrains - Perl extension for blah blah blah

=head1 SYNOPSIS

  use WWW::UKTrains;
  blah blah blah

=head1 DESCRIPTION

Stub documentation for WWW::UKTrains, created by h2xs. It looks like the
author of the extension was negligent enough to leave the stub
unedited.

Blah blah blah.

=head2 EXPORT

None by default.



=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Simon Cozens, E<lt>simon@apple.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2009 by Simon Cozens

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

package WWW::UKTrains::AccessibleTimetables;
package WWW::UKTrains::Journey;
sub cheapest {
    my $self = shift;
    if ($self->{advance_fare}) { return $self->{advance_fare} }
    if ($self->{offpeak_fare}) { return $self->{offpeak_fare} }
    return $self->{anytime_fare}
}

sub start_time { # As Time::Piece
    my $self = shift;
    $self->{_start_time} =~ s/\s//g;
    my $r;
    eval { $r = 
    Time::Piece->strptime($self->{date}." ".$self->{_start_time}, "%F %H:%M");
    }; 
    if ($@) { use Data::Dumper; print Dumper($self); die "Something wrong" }
    return $r;
}

sub end_time { # As Time::Piece
    my $self = shift;
    $self->{_end_time} =~ s/\s//g;
    $self->start_time; # because we can
    Time::Piece->strptime($self->{date}." ".$self->{_end_time}, "%F %H:%M");
}

package WWW::UKTrains::NationalRail;
use Time::Piece;
use URI::Escape;
use WWW::Mechanize;
use Web::Scraper;

sub timetable_url {
    my %params = (
        AoD => "DEPART",
        time => Time::Piece->new(),
        @_
    );
    if ($params{time} && !UNIVERSAL::isa($params{time}, "Time::Piece")) {
        die "Time parameter must be a Time::Piece object";
    }
    my $url = "http://ojp.nationalrail.co.uk/en/pj/jp/?";
    $url .= "from.searchTerm=$params{dep}&";
    $url .= "to.searchTerm=$params{dst}&";
    $url .= "timeOfOutwardJourney.day=".$params{time}->mday."&";
    $url .= "timeOfOutwardJourney.month=".$params{time}->fullmonth."&";
    $url .= "timeOfOutwardJourney.hour=".$params{time}->hour."&";
    $url .= "timeOfOutwardJourney.minute=".uri_escape(15*int($params{time}->min/15))."&";
    $url .= "changes=9&timeOfOutwardJourney.arrivalOrDeparture=$params{AoD}&referer=kb_miniqjp";
    return $url;
}

sub journeys {
    my %stuff = @_;
    my $mech = WWW::Mechanize->new();
    $stuff{time} ||= Time::Piece->new();
    $mech->get(timetable_url(%stuff));
    $mech->form_name("resultsForm");
    $mech->click_button(value => "CHECK FARES");
    my $scraper = scraper { process "td", "stuff[]" => "TEXT" };
    my $scraper2 = scraper { process "th.resHead", "stuff[]" => "TEXT" };
    my $ds = $scraper->scrape($mech->response);
    my @things = @{$ds->{stuff}};
    $ds = $scraper2->scrape($mech->response);
    my @headers = @{$ds->{stuff}}; 
    shift @headers;
    my $nothing_count = @headers - 6; 
    splice @things, 0, 17;
    my @journeys;
    my @headers = (qw(_start_time _end_time duration changes),
        (map { "nothing$_" } (1..$nothing_count) ),
        qw(advance_fare offpeak_fare anytime_fare));

    
    while (my @row = splice (@things, 0, 5)) {
        my $h = shift @headers;
        for (0..4) { 
            if ($h =~ /fare/) { $row[$_] = $row[$_] =~ /([\d\.]+)/ ? $1 : "" }
            $journeys[$_]{$h} = $row[$_] unless $h =~ /nothing/;
        }
    }
    for (0..4) { 
        $journeys[$_]{date} = $stuff{time}->ymd; # XXX Not true at extremities
        bless ($journeys[$_], "WWW::UKTrains::Journey")
    }
    return grep {$_->{_start_time}} @journeys;
}

1;
package WWW::UKTrains::Stations;
our %abbr2station;
our %station2abbr;
my $list;
while (<DATA>) {
    $list .= $_;
    chomp;
    my ($a, $s) = split / /, $_,2;
    $abbr2station{$a} = $s;
    $station2abbr{$s} = $a;
}

sub complete {
    my $partial = shift;
    return if length $partial < 3;
    my @options;
    push @options, $1 while $list =~ /^... ($partial.*)/gim;
    return @options;
}

1;

__DATA__
ABW Abbey Wood
ABE Aber
ACY Abercynon
ABA Aberdare
ABD Aberdeen
AUR Aberdour
AVY Aberdovey
ABH Abererch
AGV Abergavenny
AGL Abergele & Pensarn
AYW Aberystwyth
ACR Accrington
AAT Achanalt
ACN Achnasheen
ACH Achnashellach
ACK Acklington
ACL Acle
ACG Acocks Green
ACB Acton Bridge
ACB Acton Bridge Cheshire
ACC Acton Central
AML Acton Main Line
ADD Adderley Park
ADW Addiewell
ASN Addlestone
ADM Adisham
ADC Adlington (Cheshire)
ADL Adlington (Lancs)
ADC Adlington Cheshire
ADL Adlington Lancs
AWK Adwick
AIG Aigburth
ANS Ainsdale
AIN Aintree
AIR Airbles
ADR Airdrie
AYP Albany Park
ALB Albrighton
ALD Alderley Edge
AMT Aldermaston
AHT Aldershot
AGT Aldrington
AAP Alexandra Palace
AXP Alexandra Parade
ALX Alexandria
ALF Alfreton
ALW Allens West
ALO Alloa
ASS Alness
ALM Alnmouth
ALR Alresford
ALR Alresford Essex
ASG Alsager
ALN Althorne
ALN Althorne Essex
ALP Althorpe
ABC Altnabreac
AON Alton
ATW Alton Towers
ALT Altrincham
ALV Alvechurch
AMB Ambergate
AMY Amberley
AMR Amersham
AMF Ammanford
ANC Ancaster
AND Anderston
ADV Andover
ANZ Anerley
AGR Angel Road
ANG Angmering
ANN Annan
ANL Anniesland
AFV Ansdell & Fairhaven
ANM Antrim <Nir>
APP Appleby
APD Appledore (Kent)
APF Appleford
APB Appley Bridge
APS Apsley
ARB Arbroath
ARD Ardgay
AUI Ardlui
ADS Ardrossan Harbour
ASB Ardrossan South Beach
ADN Ardrossan Town
ADK Ardwick
AGS Argyle Street
ARG Arisaig
ARW Arklow <Cie>
ARL Arlesey
AWT Armathwaite
ARN Arnside
ARR Arram
ART Arrochar & Tarbet
ARU Arundel
ACT Ascot
ACT Ascot (Berks)
AUW Ascott-under-Wychwood
ASH Ash
AHV Ash Vale
ABY Ashburys
ASC Ashchurch for Tewkesbury
ASF Ashfield
AFS Ashford (Surrey)
AFK Ashford International
ASI Ashford International (Eurostar)
AFS Ashford Surrey
ASY Ashley
AHD Ashtead
AHN Ashton-under-Lyne
AHS Ashurst
AHS Ashurst (Kent)
ABF Ashurst Bald Face Stag (By bus)
ANF Ashurst New Forest
AWM Ashwell & Morden
ASK Askam
ALK Aslockton
ASP Aspatria
APG Aspley Guise
AST Aston
ATR Athenry <Cie>
ATH Atherstone
ATN Atherton
ATN Atherton Manchester
ATO Athlone <Cie>
ATY Athy <Cie>
ATT Attadale
ATB Attenborough
ATL Attleborough
AUK Auchinleck
AUD Audley End
AUG Aughton Park
AVM Aviemore
AVF Avoncliff
AVN Avonmouth
AXM Axminster
AYS Aylesbury
AVP Aylesbury Vale Parkway
AYL Aylesford
AYH Aylesham
AYR Ayr
BAC Bache
BAJ Baglan
BAG Bagshot
BLD Baildon
BIO Baillieston
BAB Balcombe
BDK Baldock
BAL Balham
BAX Ballina <Cie>
BSG Ballinasloe <Cie>
BHC Balloch
BBY Ballybrophy <Cie>
BAQ Ballycullane <Cie>
BHN Ballyhaunis <Cie>
BMA Ballymena <Nir>
BAO Ballymote <Cie>
BSI Balmossie
BMB Bamber Bridge
BAM Bamford
BNV Banavie
BAN Banbury
BNG Bangor (Gwynedd)
BAH Bank Hall
BAD Banstead
BNU Banteer <Cie>
BSS Barassie
ZBB Barbican
BLL Bardon Mill
BAR Bare Lane
BGI Bargeddie
BGD Bargoed
BKG Barking
ZBK Barking Underground
BRT Barlaston
BPL Barlaston Orchard Place
BMG Barming
BRM Barmouth
BNH Barnehurst
BNS Barnes
BNI Barnes Bridge
BTB Barnetby
BAA Barnham
BNL Barnhill
BNY Barnsley
BNX Barnsley (Bus Via Don)
BNP Barnstaple
BTG Barnt Green
BRR Barrhead
BRL Barrhill
BAV Barrow Haven
BWS Barrow Upon Soar
BIF Barrow-in-Furness
BWS Barrow-upon-Soar
BRY Barry
BYD Barry Docks
BYI Barry Island
BYL Barry Links
BAU Barton-on-Humber
BSO Basildon
BSK Basingstoke
BBL Bat & Ball
BTH Bath Spa
BHG Bathgate
BTL Batley
BTT Battersby
BAK Battersea Park
BAT Battle
BLB Battlesbridge
BAY Bayford
BCF Beaconsfield
BER Bearley
BRN Bearsden
BSD Bearsted
BSL Beasdale
BEU Beaulieu Road
BEL Beauly
BEB Bebington
BCC Beccles
BEC Beckenham Hill
BKJ Beckenham Junction
BDM Bedford
BSJ Bedford St Johns
BDH Bedhampton
BMT Bedminster
BEH Bedworth
BDW Bedwyn
BEE Beeston
BKS Bekesbourne
BFC Belfast Central <Nir>
BLV Belle Vue
BLG Bellgrove
BGM Bellingham
BGM Bellingham London
BLH Bellshill
BLM Belmont
BLP Belper
BEG Beltring
BVD Belvedere
BEM Bempton
BEY Ben Rhydding
BEF Benfleet
BEN Bentham
BTY Bentley
BTY Bentley (Hants)
BYK Bentley (South Yorks)
BAS Bere Alston
BFE Bere Ferrers
BKM Berkhamsted
BKW Berkswell
BYA Berney Arms
BBW Berry Brow
BRS Berrylands
BRK Berwick
BRK Berwick (Sussex)
BWK Berwick-on-Tweed
BWK Berwick-upon-Tweed
BES Bescar Lane
BSC Bescot Stadium
BTO Betchworth
BET Bethnal Green
BYC Betws-y-Coed
BEV Beverley
BEX Bexhill
BXY Bexley
BXH Bexleyheath
BCS Bicester North
BIT Bicester Town
BKL Bickley
BID Bidston
BIW Biggleswade
BBK Bilbrook
BIC Billericay
BIL Billingham
BIL Billingham Cleveland
BIG Billingshurst
BIN Bingham
BIY Bingley
BCG Birchgrove
BCH Birchington-on-Sea
BCH Birchington-on-sea
BWD Birchwood
BIK Birkbeck
BDL Birkdale
BKC Birkenhead Central
BKQ Birkenhead Hamilton Square
BKN Birkenhead North
BKP Birkenhead Park
BHI Birmingham International
BMO Birmingham Moor Street
BHM Birmingham New Street
BSW Birmingham Snow Hill
BIA Bishop Auckland
BBG Bishopbriggs
BIB Bishops Lydeard
BIS Bishops Stortford
BIP Bishopstone
BIR Bishopstone (Hill Rise By bus)
BIP Bishopstone (Sussex)
BPT Bishopton
BPT Bishopton (Strathclyde)
BTE Bitterne
BBN Blackburn
BFR Blackfriars (London) 
BKH Blackheath
BHO Blackhorse Road
BPN Blackpool North
BPB Blackpool Pleasure Beach
BPS Blackpool South
BLK Blackrod
BAW Blackwater
BFF Blaenau Ffestiniog
BLA Blair Atholl
BAI Blairhill
BKT Blake Street
BKD Blakedown
BLT Blantyre
BLO Blaydon
BSB Bleasby
BLY Bletchley
BLX Bloxwich
BWN Bloxwich North
BLN Blundellsands & Crosby
BYB Blythe Bridge
BOD Bodmin Parkway
BOR Bodorgan
BOG Bognor Regis
BGS Bogston
BON Bolton
BTD Bolton-on-Dearne
BKA Bookham
BOC Bootle
BOC Bootle Cumbria
BNW Bootle New Strand
BOT Bootle Oriel Road
BBS Bordesley
BDZ Bordon
BRG Borough Green & Wrotham
BRH Borth
BOH Bosham
BSN Boston
BOE Botley
BTF Bottesford
BNE Bourne End
BMH Bournemouth
BRV Bournville
BWB Bow Brickhill
BOP Bowes Park
BWG Bowling
BXW Boxhill & Westhumble
BXX Boxhill Burford Br Hotel
BOQ Boyle <Cie>
BCE Bracknell
BDQ Bradford Forster Square
BDI Bradford Interchange
BOA Bradford-on-Avon
BDN Brading
BTR Braintree
BTP Braintree Freeport
BML Bramhall
BLE Bramley
BMY Bramley (Hants)
BMY Bramley Hants
BLE Bramley W Yorks
BMP Brampton (Cumbria)
BRP Brampton (Suffolk)
BMP Brampton Cumbria
BCN Branchton
BND Brandon
BSM Branksome
BZY Bray <Cie>
BYS Braystones
BYS Braystones Cumbria
BDY Bredbury
BRC Breich
BFD Brentford
BRE Brentwood
BWO Bricket Wood
LBG Bridge (London)
BEA Bridge of Allan
BRO Bridge of Orchy
BGN Bridgend
BDG Bridgeton
BWT Bridgwater
BDT Bridlington
BRF Brierfield
BGG Brigg
BGH Brighouse
BTN Brighton
BMD Brimsdown
BNT Brinnington
XPB Bristol Airport (Bus)
BPW Bristol Parkway
BRI Bristol Temple Meads
BHD Brithdir
RBS British Steel Redcar
BNF Briton Ferry
BRX Brixton
BGE Broad Green
BDB Broadbottom
BSR Broadstairs
BCU Brockenhurst
BHS Brockholes
BCY Brockley
BNR Brockley Whins
BOM Bromborough
BMR Bromborough Rake
BMC Bromley Cross
BMC Bromley Cross Lancs
BMN Bromley North
BMS Bromley South
BMV Bromsgrove
BSY Brondesbury
BSP Brondesbury Park
BPK Brookmans Park
BKO Brookwood
BME Broome
BMF Broomfleet
BRA Brora
BUH Brough
BYF Broughty Ferry
BXB Broxbourne
BCV Bruce Grove
BDA Brundall
BGA Brundall Gardens
BSU Brunstane
BRW Brunswick
BRU Bruton
BYN Bryn
BUC Buckenham
BUC Buckenham (Norfolk)
BCK Buckley
BUK Bucknell
BSV Buckshaw Village
BUA Bude (Bus)
BGL Bugle
BHR Builth Road
BLW Bulwell
BUE Bures
BUG Burgess Hill
BUY Burley Park
BUW Burley-in-Wharfedale
BNA Burnage
BUD Burneside
BUD Burneside (Cumbria)
BNM Burnham
BNM Burnham (Bucks)
BUU Burnham-on-Crouch
BUB Burnley Barracks
BNC Burnley Central
BYM Burnley Manchester Road
BUI Burnside
BUI Burnside (Strathclyde)
BTS Burntisland
BCB Burscough Bridge
BCJ Burscough Junction
BUO Bursledon
BUJ Burton Joyce
BUT Burton-on-Trent
BSE Bury St Edmunds
BUS Busby
BHK Bush Hill Park
BSH Bushey
BUL Butlers Lane
BXD Buxted
BUX Buxton
BFN Byfleet & New Haw
BYE Bynea
CAD Cadoxton
CGW Caergwrle
CPH Caerphilly
CWS Caersws
CAH Cahir <Cie>
CDT Caldicot
CIR Caledonian Rd & Barnsbury
CSK Calstock
CDU Cam & Dursley
CAM Camberley
CBN Camborne
CBG Cambridge
XEC Cambridge (Drummer Street Bus Station)
CBH Cambridge Heath
CBL Cambuslang
CMD Camden Road
CMO Camelon
CMP Campile <Cie>
CNL Canley
CAO Cannock
CST Cannon Street (London)
CNN Canonbury
CBE Canterbury East
CBW Canterbury West
CNY Cantley
CPU Capenhurst
CBB Carbis Bay
CDD Cardenden
CDB Cardiff Bay
CDF Cardiff Central
CDQ Cardiff Queen Street
CDO Cardonald
CDR Cardross
CRF Carfin
CAK Cark
CAK Cark & Cartmel
CAR Carlisle
CAW Carlow <Cie>
CTO Carlton
CLU Carluke
CMN Carmarthen
CML Carmyle
CNF Carnforth
CAN Carnoustie
CAY Carntyne
CPK Carpenders Park
CAG Carrbridge
CKA Carrick-On-Shannon <Cie>
CKU Carrick-On-Suir <Cie>
CSH Carshalton
CSB Carshalton Beeches
CRS Carstairs
CDY Cartsdyke
CBP Castle Bar Park
CLC Castle Cary
CLB Castlebar <Cie>
CCN Castleconnell <Cie>
CFD Castleford
CSE Castlerea <Cie>
CAS Castleton
CAS Castleton (Manchester)
CSM Castleton Moor
CAT Caterham
CTF Catford
CFB Catford Bridge
CYS Cathays
CCT Cathcart
CTL Cattal
CAZ Cattrick Garrison Bus
CAU Causeland
CYB Cefn-y-Bedd
CTH Chadwell Heath
CFH Chafford Hundred
CFO Chalfont & Latimer
CFO Chalfont and Latimer
CHW Chalkwell
CFR Chandlers Ford
CEF Chapel-en-le-Frith
CPN Chapelton
CPN Chapelton (Devon)
CLN Chapeltown
CLN Chapeltown (South Yorks)
CWC Chappel & Wakes Colne
CHG Charing
CHC Charing Cross (Glasgow)
CHX Charing Cross (London)
CHC Charing Cross Glasgow
CHG Charing Kent
CBY Charlbury
CHJ Charleville <Cie>
CTN Charlton
CRT Chartham
CSR Chassen Road
CTE Chatelherault
CTM Chatham
CHT Chathill
CHU Cheadle Hulme
CHE Cheam
CED Cheddington
CEL Chelford
CEL Chelford Cheshire
CHM Chelmsford
CHM Chelmsford (Essex)
CLD Chelsfield
CNM Cheltenham Spa
CPW Chepstow
CYT Cherry Tree
CHY Chertsey
ZCM Chesham <Lul>
CHN Cheshunt
CSN Chessington North
CSS Chessington South
CTR Chester
CRD Chester Road
CLS Chester-le-Street
CHD Chesterfield
CSW Chestfield & Swalecliffe
CNO Chetnole
CCH Chichester
CIL Chilham
CHL Chilworth
CHI Chingford
CLY Chinley
CPM Chippenham
CHP Chipstead
CRK Chirk
CIT Chislehurst
CHK Chiswick
CHO Cholsey
CRL Chorley
CLW Chorleywood
CHR Christchurch
CHH Christs Hospital
CTW Church & Oswaldtwistle
CHF Church Fenton
CTT Church Stretton
CIM Cilmeri
CTK City Thameslink
CLT Clacton on Sea
CLT Clacton-on-Sea
CLA Clandon
CPY Clapham (North Yorks)
CPY Clapham (North Yorkshire)
CLP Clapham High Street
CLJ Clapham Junction
CPT Clapton
CLQ Clara <Cie>
CLR Clarbeston Road
CMI Claremorris <Cie>
CKS Clarkston
CLV Claverdon
CLG Claygate
CLE Cleethorpes
CEA Cleland
CLI Clifton
CFN Clifton Down
CLI Clifton Manchester
CLH Clitheroe
CLK Clock House
CLX Clonmel <Cie>
CLZ Cloughjordan <Cie>
CUW Clunderwen
CYK Clydebank
CBC Coatbridge Central
CBS Coatbridge Sunnyside
COA Coatdyke
COQ Cobh <Cie>
CSD Cobham & Stoke D'Abernon
CSD Cobham & Stoke d'Abernon
COX Cockermouth Main Street
CSL Codsall
CGN Cogan
COL Colchester
CET Colchester Town
CEI Coleraine <Nir>
CEH Coleshill Parkway
CLM Collingham
CLL Collington
COU Collooney <Cie>
CNE Colne
CWL Colwall
CWB Colwyn Bay
CME Combe
CME Combe Oxon
COM Commondale
CNG Congleton
CNS Conisbrough
CON Connel Ferry
CEY Cononley
CNP Conway Park
CNW Conwy
COB Cooden Beach
COO Cookham
CBR Cooksbridge
COE Coombe Cornwall
COE Coombe Halt
COP Copplestone
CRB Corbridge
COR Corby
XXZ Corby Bus Link
CBZ Corby-Peterborough Bus
COK Cork City (cie)
CKH Corkerhill
CKL Corkickle
CPA Corpach
CRR Corrour
COY Coryton
CSY Coseley
COS Cosford
CSA Cosham
CGM Cottingham
COT Cottingley
CDS Coulsdon South
COV Coventry
CWN Cowden
CWN Cowden (Kent)
COC Cowden Crossroads (By bus)
COW Cowdenbeath
CRA Cradley Heath
CGD Craigendoran
CRU Craignure (Isle of Mull)
CRM Cramlington
CRV Craven Arms
CRW Crawley
CRY Crayford
CDI Crediton
CES Cressing
CES Cressing Essex
CSG Cressington
CWD Creswell
CRE Crewe
CKN Crewkerne
CWH Crews Hill
CNR Crianlarich
CCC Criccieth
CRI Cricklewood
CFF Croftfoot
CFT Crofton Park
CMR Cromer
CMF Cromford
CKT Crookston
CRG Cross Gates
CKY Cross Keys
CFL Crossflatts
COI Crosshill
CKY Crosskeys
CMY Crossmyloof
CSO Croston
CRH Crouch Hill
COH Crowborough
CWU Crowhurst
CWE Crowle
CRN Crowthorne
ZCO Croxley
CRO Croy
CYP Crystal Palace
CUD Cuddington
CUF Cuffley
CUM Culham
CUA Culrain
CUB Cumbernauld
CUP Cupar
CUH Curriehill
CUX Cuxton
CMH Cwmbach
CWM Cwmbran
CYN Cynghordy
DDK Dagenham Dock
DSY Daisy Hill
DAG Dalgety Bay
DAL Dalmally
DAK Dalmarnock
DAM Dalmeny
DMR Dalmuir
DLR Dalreoch
DLY Dalry
DLS Dalston
DLS Dalston (Cumbria)
DLK Dalston Kingsland
DLT Dalton
DLT Dalton Cumbria
DLW Dalwhinnie
DNY Danby
DCT Danescourt
DZY Danzey
DFZ Darfield (Bus Via Don)
DAR Darlington
DAN Darnall
DSM Darsham
DFD Dartford
DRT Darton
DWN Darwen
DAT Datchet
DVN Davenport
DWL Dawlish
DWW Dawlish Warren
DEA Deal
DEN Dean
DNN Dean Lane
DEN Dean Wilts
DGT Deansgate
DGY Deganwy
DHN Deighton
DLM Delamere
DBD Denby Dale
DNM Denham
DGC Denham Golf Club
DMK Denmark Hill
DNT Dent
DTN Denton
DEP Deptford
DBY Derby
DBR Derby Road
DBR Derby Road (Ipswich)
DEB Dereham Coach
DKR Derker
DPT Devonport
DPT Devonport Devon
DOC Devonport Dockyard
DEW Dewsbury
DID Didcot Parkway
DIG Digby & Sowton
DMH Dilton Marsh
DMG Dinas (Rhondda)
DNS Dinas Powys
DMG Dinas Rhondda
DGL Dingle Road
DIN Dingwall
DND Dinsdale
DTG Dinting
DSL Disley
DIS Diss
DOC Dockyard
DOD Dodworth
DOL Dolau
DLH Doleham
DLG Dolgarrog
DWD Dolwyddelan
DON Doncaster
DCH Dorchester South
DCW Dorchester West
DOR Dore
DOR Dore and Totley
DKG Dorking
DPD Dorking Deepdene
DKG Dorking Main
DKT Dorking West
DMS Dormans
DDG Dorridge
DGS Douglas Isle of Man
DVH Dove Holes
DVP Dover Priory
DVC Dovercourt
DVY Dovey Junction
DOW Downham Market
DRG Drayton Green
DYP Drayton Park
DRM Drem
DRF Driffield
DRI Drigg
DRA Drogheda <Cie>
DTW Droitwich Spa
DMD Dromod <Cie>
DRO Dronfield
DMC Drumchapel
DFR Drumfrochar
DRU Drumgelloch
DMY Drumry
DCL Dublin Connolly <Cie>
DFP Dublin Ferryport
DHT Dublin Heuston <Cie>
DBP Dublin Pearse <Cie>
DPS Dublin Port - Stena
DUD Duddeston
DDP Dudley Port
DFI Duffield
DRN Duirinish
DST Duke Street
DUL Dullingham
DBC Dumbarton Central
DBE Dumbarton East
DUM Dumbreck
DMF Dumfries
ZZZ DUMMY TEST
DMP Dumpton Park
DLO Dun Laoghaire <Cie>
DUN Dunbar
DBL Dunblane
DCG Duncraig
DUK Dundalk <Cie>
DEE Dundee
DFL Dunfermline Queen Margaret
DFE Dunfermline Town
DKD Dunkeld
DKD Dunkeld & Birnam
DNL Dunlop
DNO Dunrobin Castle
DUU Duns (By Bus)
DOT Dunston
DNG Dunton Green
DHM Durham
DUR Durrington-on-Sea
DYC Dyce
DYF Dyffryn Ardudwy
EAG Eaglescliffe
EAL Ealing Broadway
ERL Earlestown
EAR Earley
EAD Earlsfield
EAS Earlston (Borders)
ELD Earlswood (Surrey)
EWD Earlswood (West Midlands)
EBL East Boldon
ECW East Cowes
ECR East Croydon
EDY East Didsbury
EDW East Dulwich
EFL East Farleigh
EGF East Garforth
EGR East Grinstead
EKL East Kilbride
EML East Malling
XMT East Midlands Airport
EMD East Midlands Parkway
ETL East Tilbury
EWR East Worthing
EBN Eastbourne
EBK Eastbrook
EST Easterhouse
ERA Eastham Rake
ESL Eastleigh
EGN Eastrington
EBV Ebbw Vale Parkway
ECC Eccles
ECC Eccles (Manchester)
ECS Eccles Road
ECL Eccleston Park
EDL Edale
EDN Eden Park
XFJ Eden Project
EBR Edenbridge
EBT Edenbridge Town
EDG Edge Hill
EDB Edinburgh
EDP Edinburgh Park
EDB Edinburgh Waverley
EDR Edmonton Green
EFF Effingham Junction
EGG Eggesford
EGH Egham
EGT Egton
EPH Elephant & Castle
ELG Elgin
ELP Ellesmere Port
ELE Elmers End
ESD Elmstead Woods
ESW Elmswell
ELR Elsecar
ESM Elsenham
ESM Elsenham Essex
ELS Elstree & Borehamwood
ELW Eltham
ELO Elton & Orston
ELY Ely
EMP Emerson Park
EMS Emsworth
EFD Enfield (Ireland) <Cie>
ENC Enfield Chase
ENL Enfield Lock
ENF Enfield Town
ENN Ennis <Cie>
ENS Enniscorthy <Cie>
ENT Entwistle
EPS Epsom
EPD Epsom Downs
ERD Erdington
ERI Eridge
ERB Eridge (A26 Bus stop)
ERH Erith
ESH Esher
EXR Essex Road
ETC Etchingham
EUS Euston (London)
EBA Euxton Balshaw Lane
EVE Evesham
EWE Ewell East
EWW Ewell West
EXC Exeter Central
EXD Exeter St David's
EXD Exeter St Davids
EXT Exeter St Thomas
EXG Exhibition Centre
EXG Exhibition Centre Glasgow
EXM Exmouth
EXN Exton
EYN Eynsford
FLS Failsworth
FRB Fairbourne
FRF Fairfield
FRL Fairlie
FRW Fairwater
FCN Falconwood
FKG Falkirk Grahamston
FKK Falkirk High
FOC Falls of Cruachan
FMR Falmer
FAL Falmouth Docks
FMT Falmouth Town
FRM Fareham
FNB Farnborough (Main)
FNB Farnborough Main
FNN Farnborough North
FNC Farncombe
FNH Farnham
FNR Farningham Road
FNW Farnworth
FAR Farranfore <Cie>
ZFD Farringdon
FLD Fauldhouse
FAV Faversham
FGT Faygate
FAZ Fazakerley
FRN Fearn
FEA Featherstone
FLX Felixstowe
FEG Fellgate Metro
FEL Feltham
FST Fenchurch Street (London)
FNT Feniton
FEN Fenny Stratford
FER Fernhill
FRY Ferriby
FYS Ferryside
FFA Ffairfach
FIL Filey
FIT Filton Abbey Wood
FIT Filton Abbeywood
FNY Finchley Road & Frognal
FPK Finsbury Park
FIN Finstock
FSB Fishbourne (Sussex)
FSG Fishersgate
FGH Fishguard Harbour
FSK Fiskerton
FZW Fitzwilliam
FWY Five Ways
FLE Fleet
FLM Flimby
FLN Flint
FLT Flitwick
FLI Flixton
FLF Flowery Field
FKC Folkestone Central
FKW Folkestone West
FOD Ford
FOG Forest Gate
FOH Forest Hill
FBY Formby
FOR Forres
FRS Forsinard
FTM Fort Matilda
FTW Fort William
FOT Fota <Cie>
FOK Four Oaks
FOX Foxfield
FXF Foxford <Cie>
FXN Foxton
FRT Frant
FTN Fratton
FRE Freshfield
FFD Freshford
FML Frimley
FRI Frinton on Sea
FRI Frinton-on-Sea
FZH Frizinghall
FRD Frodsham
FRO Frome
FLW Fulwell
FNV Furness Vale
FZP Furze Platt
GNB Gainsborough Central
GBL Gainsborough Lea Road
GAL Galashiels (By Bus)
GWY Galway <Cie>
GCH Garelochhead
GRF Garforth
GGV Gargrave
GAR Garrowhill
GRS Garscadden
GSD Garsdale
GSN Garston (Hertfordshire)
GSN Garston (Herts)
GRM Garston (Merseyside)
GSW Garswood
GRH Gartcosh
GMG Garth (Bridgend)
GMG Garth (Mid-Glamorgan)
GTH Garth (Powys)
GVE Garve
GST Gathurst
GTY Gatley
GTW Gatwick Airport
GGJ Georgemas Junction
GER Gerrards Cross
GDP Gidea Park
GFN Giffnock
GIG Giggleswick
GBD Gilberdyke
GFF Gilfach Fargoed
GIL Gillingham (Dorset)
GLM Gillingham (Kent)
GSC Gilshochill
GIP Gipsy Hill
GIR Girvan
GLS Glaisdale
GCW Glan Conwy
GGT Glasgow Airport
GLC Glasgow Central
GLQ Glasgow Queen Street
GLH Glasshoughton
GLZ Glazebrook
GLE Gleneagles
GLF Glenfinnan
GLG Glengarnock
GLT Glenrothes With Thornton
GLT Glenrothes with Thornton
GLO Glossop
GCR Gloucester
GLY Glynde
GOB Gobowen
GOD Godalming
GDL Godley
GDN Godstone
GOE Goldthorpe
GOZ Goldthorpe (Bus Via Don)
GOF Golf Street
GOL Golspie
GOM Gomshall
GMY Goodmayes
GOO Goole
GTR Goostrey
GDH Gordon Hill
GOY Gorey <Cie>
GOR Goring & Streatley
GBS Goring-by-Sea
GTO Gorton
GPO Gospel Oak
GRK Gourock
GWN Gowerton
GOX Goxhill
GPK Grange Park
GOS Grange-over-Sands
GOS Grange-Over-Sands
GTN Grangetown
GTN Grangetown (Glamorgan)
GRA Grantham
GRT Grateley
GVH Gravelly Hill
GRV Gravesend
GRY Grays
GTA Great Ayton
GRB Great Bentley
GRC Great Chesterford
GCT Great Coates
GMV Great Malvern
GMN Great Missenden
GYM Great Yarmouth
GNL Green Lane
GNR Green Road
GBK Greenbank
GRL Greenfaulds
GNF Greenfield
GFD Greenford
GNH Greenhithe
GNH Greenhithe for Bluewater
GKC Greenock Central
GKW Greenock West
GNW Greenwich
GEA Gretna Green
GSO Greystones <Cie>
GMD Grimsby Docks
GMB Grimsby Town
GRN Grindleford
GMT Grosmont
GRP Grove Park
GUI Guide Bridge
GLD Guildford
GSY Guiseley
GUN Gunnersbury
GSL Gunnislake
GNT Gunton
GWE Gwersyllt
GYP Gypsy Lane
HAB Habrough
HCB Hackbridge
HKC Hackney Central
HAC Hackney Downs
HKW Hackney Wick
HDM Haddenham & Thame Parkway
HAD Haddiscoe
HDF Hadfield
HDW Hadley Wood
HGF Hag Fold
HAG Hagley
HMY Hairmyres
HAL Hale
HAL Hale (Manchester)
HAS Halesworth
HED Halewood
HFX Halifax
HLG Hall Green
HID Hall I Th Wood
HLR Hall Road
HID Hall-i-th-Wood
HAI Halling
HWH Haltwhistle
HMT Ham Street
HME Hamble
HNC Hamilton Central
BKQ Hamilton Square
HNW Hamilton West
HMM Hammerton
HMD Hampden Park
HMD Hampden Park (Sussex)
HDH Hampstead Heath
HMP Hampton
HMP Hampton (London)
HMC Hampton Court
HMW Hampton Wick
HIA Hampton-in-Arden
HSD Hamstead
HSD Hamstead (Birmingham)
HAM Hamworthy
HND Hanborough
HTH Handforth
HAN Hanwell
HPN Hapton
HRL Harlech
HDN Harlesden
HRD Harling Road
HLN Harlington
HLN Harlington (Beds)
HWM Harlow Mill
HWN Harlow Town
HRO Harold Wood
HPD Harpenden
HRM Harrietsham
HGY Harringay
HRY Harringay Green Lanes
HRR Harrington
HGT Harrogate
HRW Harrow & Wealdstone
HOH Harrow-on-the-Hill
HTF Hartford
HTF Hartford (Cheshire)
HBY Hartlebury
HPL Hartlepool
HTW Hartwood
HPQ Harwich International
HWC Harwich Town
HSL Haslemere
HSK Hassocks
HGS Hastings
HTE Hatch End
HAT Hatfield
HFS Hatfield & Stainforth
HAT Hatfield (Herts)
HAP Hatfield Peverel
HSG Hathersage
HTY Hattersley
HTN Hatton
HAV Havant
HVN Havenhouse
HVF Haverfordwest
HWD Hawarden
HWB Hawarden Bridge
HWK Hawick (By Bus)
HKH Hawkhead
HDB Haydon Bridge
HYR Haydons Road
HAY Hayes & Harlington
HYS Hayes (Kent)
HYL Hayle
HYM Haymarket
HHE Haywards Heath
HAZ Hazel Grove
HCN Headcorn
HDY Headingley
HDL Headstone Lane
HDG Heald Green
HLI Healing
HHL Heath High Level
HLL Heath Low Level
HXX Heathrow Airport T123
HAF Heathrow Airport T4
HWV Heathrow Terminal 5
HTC Heaton Chapel
HBD Hebden Bridge
HEC Heckington
HDE Hedge End
HNF Hednesford
HEI Heighington
HLC Helensburgh Central
HLU Helensburgh Upper
HLD Hellifield
HMS Helmsdale
HSB Helsby
HML Hemel Hempstead
HEN Hendon
HNG Hengoed
HNL Henley-in-Arden
HOT Henley-on-Thames
HEL Hensall
HFD Hereford
HNB Herne Bay
HNH Herne Hill
HER Hersham
HFE Hertford East
HFN Hertford North
HES Hessle
HSW Heswall
HEV Hever
HBF Hever (Brocas Farm By bus)
HEW Heworth
HEX Hexham
HYD Heyford
HHB Heysham Port
HIB High Brooms
HST High St (Glasgow)
HST High Street (Glasgow)
ZHS High Street Kensington Underground
HWY High Wycombe
HGM Higham
HGM Higham (Kent)
HIP Highams Park
HIG Highbridge & Burnham
HHY Highbury & Islington
HTO Hightown
HLB Hildenborough
HLF Hillfoot
HLE Hillington East
HLW Hillington West
HIL Hillside
HLS Hilsea
HYW Hinchley Wood
HNK Hinckley
HNK Hinckley (Leics)
HIN Hindley
HNA Hinton Admiral
HIT Hitchin
HGR Hither Green
HOC Hockley
HBN Hollingbourne
HOD Hollinwood
HCH Holmes Chapel
HLM Holmwood
HOL Holton Heath
HHD Holyhead
HLY Holytown
HMN Homerton
HYB Honeybourne
HON Honiton
HOY Honley
HPA Honor Oak Park
HOK Hook
HOO Hooton
HOP Hope (Derbyshire)
HPE Hope (Flintshire)
HPT Hopton Heath
HOR Horley
HBP Hornbeam Park
HRN Hornsey
HRS Horsforth
HRH Horsham
HSY Horsley
HIR Horton-in-Ribblesdale
HWI Horwich Parkway
HSC Hoscar
HGN Hough Green
HOU Hounslow
HOV Hove
HXM Hoveton & Wroxham
HWW How Wood
HWW How Wood (Herts)
HOW Howden
HOZ Howwood (Renfrewshire)
HOZ Howwood Strathclyde
HYK Hoylake
HBB Hubberts Bridge
HKN Hucknall
HUD Huddersfield
HUL Hull
HUL Hull Paragon
HUP Humphrey Park
HCT Huncoat
HGD Hungerford
HUB Hunmanby
HUS Hunstanton
HUN Huntingdon
HNT Huntly
HNX Hunts Cross
HUR Hurst Green
HUT Hutton Cranswick
HUY Huyton
HYC Hyde Central
HYT Hyde North
HKM Hykeham
HCR Hykeham Crossroads
HYN Hyndland
HYH Hythe
HYH Hythe (Essex)
IBM IBM
IBM IBM Halt
IFI Ifield
IFD Ilford
ILK Ilkley
IMW Imperial Wharf
INC Ince
INE Ince & Elton
INC Ince (Manchester)
INT Ingatestone
INS Insch
IGD Invergordon
ING Invergowrie
INK Inverkeithing
INP Inverkip
INV Inverness
INH Invershin
INR Inverurie
IPS Ipswich
IRL Irlam
IRV Irvine
ISL Isleworth
ISP Islip
IVR Iver
IVY Ivybridge
LVJ James Street (Liverpool)
JEQ Jewellery Quarter
JOH Johnston
JOH Johnston (Pembs)
JHN Johnstone
JHN Johnstone (Strathclyde)
JOR Jordanhill
KSL Kearsley
KSL Kearsley Manchester
KSN Kearsney
KSN Kearsney Kent
KEI Keighley
KEH Keith
KEL Kelvedon
KVD Kelvindale
KEM Kemble
KMH Kempston Hardwick
KMP Kempton Park
KMP Kempton Park Racecourse
KMS Kemsing
KML Kemsley
KEN Kendal
KLY Kenley
KEB Kenley (A22 By bus)
KNE Kennett
KNS Kennishead
KNL Kensal Green
KNR Kensal Rise
KPA Kensington Olympia
KTH Kent House
KTN Kentish Town
KTW Kentish Town West
KNT Kenton
KBK Kents Bank
KWK Keswick Bus Station
KET Kettering
KEZ Kettering (Bus via Peterborough)
KWB Kew Bridge
KWG Kew Gardens
KEY Keyham
KYN Keynsham
KDB Kidbrooke
KID Kidderminster
KDG Kidsgrove
KWL Kidwelly
KBN Kilburn High Road
KCG Kilcreggan
KLD Kildale
KDR Kildare <Cie>
KIL Kildonan
KGT Kilgetty
KNY Kilkenny <Cie>
KLL Killarney <Cie>
KMK Kilmarnock
KLM Kilmaurs
KPT Kilpatrick
KWN Kilwinning
KBC Kinbrace
KLN King's Lynn
KGM Kingham
KGH Kinghorn
KGX Kings Cross (London)
KGL Kings Langley
KLN Kings Lynn
KLB Kings Lynn Bus Station
KNN Kings Norton
KGN Kings Nympton
KGP Kings Park
KGS Kings Sutton
KGE Kingsknowe
KNG Kingston
KND Kingswood
KIN Kingussie
KIT Kintbury
KBX Kirby Cross
KKS Kirk Sandall
KIR Kirkby
KKB Kirkby in Ashfield
KIR Kirkby Merseyside
KSW Kirkby Stephen
KKB Kirkby-in-Ashfield
KBF Kirkby-in-Furness
KDY Kirkcaldy
KRK Kirkconnel
KKD Kirkdale
KKM Kirkham & Wesham
KKH Kirkhill
KKN Kirknewton
KWD Kirkwood
KTL Kirton Lindsey
KIV Kiveton Bridge
KVP Kiveton Park
KNA Knaresborough
KBW Knebworth
KNI Knighton
KCK Knockholt
KNO Knottingley
KNU Knucklas
KNF Knutsford
KYL Kyle of Lochalsh
LDY Ladybank
LAD Ladywell
LAI Laindon
LRG Lairg
LKE Lake
LAK Lakenheath
LAM Lamphey
LNK Lanark
LAN Lancaster
LAC Lancing
LAW Landywood
LGB Langbank
LHO Langho
LHL Langholm (By Bus)
LNY Langley
LNY Langley (Berks)
LGG Langley Green
LGM Langley Mill
LGS Langside
LGW Langwathby
LAG Langwith-Whaley Thorns
LAP Lapford
LPW Lapworth
LBT Larbert
LAR Largs
LRH Larkhall
LWH Lawrence Hill
LAY Layton
LAY Layton (Lancs)
LZB Lazonby & Kirkoswald
LEG Lea Green
LEH Lea Hall
LEA Leagrave
LHM Lealholm
LMS Leamington Spa
LSW Leasowe
LHD Leatherhead
LED Ledbury
LEE Lee
LEE Lee (London)
LDS Leeds
XLB Leeds Bradford Airport
LEI Leicester
LIH Leigh (Kent)
LIH Leigh Kent
LES Leigh-on-Sea
LBZ Leighton Buzzard
LEL Lelant
LTS Lelant Saltings
LEN Lenham
LNZ Lenzie
LEO Leominster
LET Letchworth Garden City
LEU Leuchars
LEU Leuchars (for St. Andrews)
LVM Levenshulme
LWS Lewes
LEW Lewisham
LEY Leyland
LEM Leyton Midland Road
LER Leytonstone High Road
LIC Lichfield City
LTV Lichfield Trent Valley
LID Lidlington
LHS Limehouse
LRK Limerick <Cie>
LCN Lincoln
LBS Lincoln Bus Station
LCN Lincoln Central
LFD Lingfield
LGD Lingwood
LIN Linlithgow
LIP Liphook
LBN Lisburn <Nir>
LSK Liskeard
LIS Liss
LVT Lisvane & Thornhill
LTK Little Kimble
LTT Little Sutton
LTL Littleborough
LIT Littlehampton
LVN Littlehaven
LTP Littleport
LVC Liverpool Central
LVJ Liverpool James Street
LIV Liverpool Lime Street
LPY Liverpool South Parkway
LST Liverpool Street (London)
LSN Livingston North
LVG Livingston South
LLA Llanaber
LBR Llanbedr
LLT Llanbister Road
LNB Llanbradach
LLN Llandaf
LDN Llandanwg
LLC Llandecwyn
LLL Llandeilo
LLV Llandovery
LLO Llandrindod
LLD Llandudno
LLJ Llandudno Junction
LLI Llandybie
LLE Llanelli
LLF Llanfairfechan
LPG Llanfairpwll
LLG Llangadog
LLM Llangammarch
LLH Llangennech
LGO Llangynllo
LLR Llanharan
LTH Llanhilleth
LLS Llanishen
LWR Llanrwst
LAS Llansamlet
LWM Llantwit Major
LNR Llanwrda
LNW Llanwrtyd
LLW Llwyngwril
LLY Llwynypia
LHA Loch Awe
LHE Loch Eil Outward Bound
LCL Lochailort
LCS Locheilside
LCG Lochgelly
LCC Lochluichart
LHW Lochwinnoch
LOC Lockerbie
LCK Lockwood
BFR London Blackfriars
LBG London Bridge
CST London Cannon Street
CHX London Charing Cross
EUS London Euston
FST London Fenchurch Street
LOF London Fields
LNE London International
KGX London Kings Cross
LST London Liverpool Street
MYB London Marylebone
PAD London Paddington
LRB London Road (Brighton)
LRD London Road (Guildford)
STP London St Pancras (Domestic)
SPX London St Pancras (Intl)
STP London St Pancras Domestic
VIC London Victoria
WAT London Waterloo
WAE London Waterloo East
LDR Londonderry <Nir>
LBK Long Buckby
LGE Long Eaton
LPR Long Preston
LGK Longbeck
LOB Longbridge
LNG Longcross
LGF Longfield
LFO Longford <Cie>
LND Longniddry
LPT Longport
LGN Longton
LOO Looe
LOT Lostock
LTG Lostock Gralam
LOH Lostock Hall
LOS Lostwithiel
LBO Loughborough
LGJ Loughborough Junction
LOW Lowdham
LSY Lower Sydenham
LWT Lowestoft
LUD Ludlow
LUT Luton
LUA Luton Airport
LTN Luton Airport Parkway
LUX Luxulyan
LYD Lydney
LYE Lye
LYE Lye (West Midlands)
LYP Lymington Pier
LYT Lymington Town
LYC Lympstone Commando
LYM Lympstone Village
LTM Lytham
MAC Macclesfield
MCN Machynlleth
MST Maesteg
MEW Maesteg (Ewenny Road)
MEW Maesteg Ewenny Road
MAG Maghull
MDN Maiden Newton
MAI Maidenhead
MDB Maidstone Barracks
MDE Maidstone East
MDW Maidstone West
MAL Malden Manor
MLG Mallaig
MAW Mallow <Cie>
MLT Malton
MVL Malvern Link
MIA Manchester Airport
MCO Manchester Oxford Road
MAN Manchester Piccadilly
MUF Manchester United FC Halt
MUF Manchester Utd Football Gd
MCV Manchester Victoria
MNE Manea
MNG Manningtree
MNP Manor Park
MNR Manor Road
MRB Manorbier
MAS Manors
MFT Mansfield
MSW Mansfield Woodhouse
MAJ Manulla Junction <Cie>
MCH March
MRN Marden
MRN Marden Kent
MAR Margate
MHR Market Harborough
MKR Market Rasen
MNC Markinch
MKT Marks Tey
MLW Marlow
MPL Marple
MSN Marsden
MSN Marsden Yorks
MSK Marske
MGN Marston Green
MTM Martin Mill
MAO Martins Heron
MTO Marton
MYH Maryhill
MYL Maryland
MYB Marylebone (London)
MRY Maryport
MAT Matlock
MTB Matlock Bath
MAU Mauldeth Road
MAX Maxwell Park
MAY Maybole
MAE Maynooth <Cie>
MZH Maze Hill
MHS Meadowhall
MEL Meldreth
MKM Melksham
MLS Melrose (By Bus)
MES Melton
MMO Melton Mowbray
MES Melton Suffolk
MEN Menheniot
MNN Menston
MEO Meols
MEC Meols Cop
MEP Meopham
MEY Merryton
MEY Merrytown
MHM Merstham
MER Merthyr Tydfil
MEV Merthyr Vale
MGM Metheringham
MCE Metrocentre
MCE MetroCentre
MEX Mexborough
MIC Micheldever
MIK Micklefield
MBR Middlesbrough
MDL Middlewood
MDG Midgham
MLF Milford (Surrey)
MFH Milford Haven
MLH Mill Hill (Lancashire)
MIL Mill Hill Broadway
MLH Mill Hill Lancs
MLB Millbrook (Bedfordshire)
MLB Millbrook (Beds)
MBK Millbrook (Hants)
MIN Milliken Park
MLM Millom
MIH Mills Hill
MIH Mills Hill (Manchester)
MIE Millstreet <Cie>
MLN Milngavie
MLR Milnrow
MKC Milton Keynes Central
XBV Minehead (Bus)
MFF Minffordd
MFD Minffordd Ffestiniog Railway
MSR Minster
MIR Mirfield
MIS Mistley
MTC Mitcham Eastfields
MIJ Mitcham Junction
MOB Mobberley
MON Monifieth
MRS Monks Risborough
MTP Montpelier
MTS Montrose
MRF Moorfields
MOG Moorgate
ZMG Moorgate
ZMG Moorgate Underground
MSD Moorside
MRP Moorthorpe
MRR Morar
MRD Morchard Road
MDS Morden South
MCM Morecambe
MTN Moreton (Dorset)
MRT Moreton (Merseyside)
MIM Moreton-in-Marsh
MFA Morfa Mawddach
MLY Morley
MPT Morpeth
MOR Mortimer
MTL Mortlake
MSS Moses Gate
MOY Mosney <Cie>
MOS Moss Side
MSL Mossley
MSL Mossley (Manchester)
MSH Mossley Hill
MPK Mosspark
MSO Moston
MTH Motherwell
MOT Motspur Park
MTG Mottingham
DBG Mottisfont & Dunbridge
MLD Mouldsworth
MCB Moulsecoomb
MFL Mount Florida
MTV Mount Vernon
MTA Mountain Ash
MBH Muine Bheag <Cie>
MOO Muir of Ord
MUI Muirend
MUL Mullingar <Cie>
MUB Musselburgh
MYT Mytholmroyd
NFN Nafferton
NLS Nailsea & Backwell
NRN Nairn
NAN Nantwich
NAR Narberth
NBR Narborough
NVR Navigation Road
NTH Neath
NMT Needham Market
NEI Neilston
NEL Nelson
NEN Nenagh <Cie>
NES Neston
NET Netherfield
NRT Nethertown
NTL Netley
NBA New Barnet
NBC New Beckenham
NBN New Brighton
NCE New Clee
NWX New Cross
NXG New Cross Gate
NCK New Cumnock
NEH New Eltham
NHY New Hey
NHL New Holland
NHE New Hythe
NLN New Lane
NEM New Malden
NMC New Mills Central
NMN New Mills Newtown
NWM New Milton
NPD New Pudsey
NSG New Southgate
NCT Newark Castle
NNG Newark North Gate
NBE Newbridge
NBG Newbridge (Ireland) <Cie>
NBY Newbury
ZNP Newbury Park Underground
NRC Newbury Racecourse
NCL Newcastle
APN Newcastle Airport
NCZ Newcastle Central Metro
NEW Newcraighall
NVH Newhaven Harbour
NVN Newhaven Town
NGT Newington
NMK Newmarket
NWE Newport (Essex)
NWP Newport (S. Wales)
NWP Newport (South Wales)
NQY Newquay
NWY Newry <Nir>
NSD Newstead
NTN Newton (Lanark)
NTN Newton (Lanarks)
NTA Newton Abbot
NAY Newton Aycliffe
NWN Newton for Hyde
NTC Newton St Cyres
NLW Newton-le-Willows
NOA Newton-on-Ayr
NWR Newtonmore
NWT Newtown (Powys)
NNP Ninian Park
NIT Nitshill
NBT Norbiton
NRB Norbury
NSB Normans Bay
NOR Normanton
NBW North Berwick
NCM North Camp
NDL North Dulwich
NFA North Fambridge
NLR North Llanrwst
NQU North Queensferry
NRD North Road
NRD North Road Darlington
NSH North Sheen
NWA North Walsham
NWB North Wembley
NTR Northallerton
NMP Northampton
NFD Northfield
NFL Northfleet
NLT Northolt Park
NUM Northumberland Park
NWI Northwich
ZND Northwood <Lul>
NTB Norton Bridge
NRW Norwich
NWD Norwood Junction
NOT Nottingham
NUN Nuneaton
NHD Nunhead
NNT Nunthorpe
NUT Nutbourne
NUF Nutfield
OKN Oakengates
OKM Oakham
OKL Oakleigh Park
OBN Oban
OCK Ockendon
OLY Ockley
XCG Okehampton
OHL Old Hill
ORN Old Roan
OLD Old Street
OLF Oldfield Park
OLM Oldham Mumps
OLW Oldham Werneth
OLT Olton
ORE Ore
OMS Ormskirk
ORP Orpington
ORR Orrell
OPK Orrell Park
OTF Otford
OUN Oulton Broad North
OUS Oulton Broad South
OUD Oundle (By Bus)
OUT Outwood
OVE Overpool
OVR Overton
OXN Oxenholme Lake District
OXF Oxford
OXS Oxshott
OXT Oxted
PAD Paddington (London)
PDW Paddock Wood
PDG Padgate
PDT Padstow (Bus)
PGN Paignton
PCN Paisley Canal
PYG Paisley Gilmour Street
PYJ Paisley St James
PAL Palmers Green
PAN Pangbourne
PNL Pannal
PTF Pantyffynnon
PAR Par
PBL Parbold
PKT Park Street
PKS Parkstone (Dorset)
PKS Parkstone Dorset
PSN Parson Street
PTK Partick
PRN Parton
PWY Patchway
PAT Patricroft
PTT Patterton
PEA Peartree
PMR Peckham Rye
PEG Pegswood
PEM Pemberton
PBY Pembrey & Burry Port
PMB Pembroke
PMD Pembroke Dock
PDK Pembroke Ferry Terminal
PNY Pen-y-Bont
PNA Penally
PEN Penarth
PCD Pencoed
PGM Pengam
PNE Penge East
PNW Penge West
PHG Penhelig
PNS Penistone
PKG Penkridge
PMW Penmaenmawr
PNM Penmere
PER Penrhiwceiber
PRH Penrhyndeudraeth
PNR Penrith
PNR Penrith North Lakes
PYN Penryn
PYN Penryn Cornwall
PES Pensarn
PES Pensarn (Gwynedd)
PHR Penshurst
PTB Pentre Bach
PTB Pentre-Bach
BPC Penychain
PNF Penyffordd
PNZ Penzance
PRW Perranwell
PRY Perry Barr
PSH Pershore
PTH Perth
PBO Peterborough
PTR Petersfield
PET Petts Wood
PEV Pevensey & Westham
PEB Pevensey Bay
PEW Pewsey
PIZ Pickering Bus
PIL Pilning
PIN Pinhoe
PIT Pitlochry
PSE Pitsea
PLS Pleasington
PLK Plockton
PLC Pluckley
PLM Plumley
PMP Plumpton
PLU Plumstead
PLY Plymouth
POK Pokesdown
PLG Polegate
PSW Polesworth
PWE Pollokshaws East
PWW Pollokshaws West
PLE Pollokshields East
PLW Pollokshields West
PMT Polmont
POL Polsloe Bridge
PON Ponders End
PYP Pont-y-Pant
PTD Pontarddulais
PFR Pontefract Baghill
PFM Pontefract Monkhill
POT Pontefract Tanshelf
PLT Pontlottyn
PYC Pontyclun
PPL Pontypool & New Inn
PPD Pontypridd
POO Poole
POP Poppleton
PTG Port Glasgow
PSL Port Sunlight
PTA Port Talbot Parkway
PTN Portadown <Nir>
PRO Portarlington <Cie>
PTC Portchester
POR Porth
PTM Porthmadog
PMG Porthmadog Harbour (Ffestiniog Railway)
PTO Portlaoise <Cie>
PLN Portlethen
PTS Portrush <Nir>
PLD Portslade
PMS Portsmouth & Southsea
PMA Portsmouth Arms
PMH Portsmouth Harbour
PPK Possilpark & Parkhouse
PBR Potters Bar
PFY Poulton-le-Fylde
PYT Poynton
PRS Prees
PSC Prescot
PRT Prestatyn
PRB Prestbury
PRE Preston
PRE Preston Lancs
PRP Preston Park
PST Prestonpans
PRA Prestwick International Airport
PTW Prestwick Town
PTL Priesthill & Darnley
PRR Princes Risborough
PRL Prittlewell
PRU Prudhoe
PUL Pulborough
PFL Purfleet
PUR Purley
PUO Purley Oaks
PUT Putney
PWL Pwllheli
PYL Pyle
QRD Quainton Road
QYD Quakers Yard
QBR Queenborough
QPK Queens Park (Glasgow)
QPW Queens Park (London)
QRP Queens Road Peckham
QRP Queens Road, Peckham
QRB Queenstown Road
QRB Queenstown Road (Battersea)
QUI Quintrel Downs
QUI Quintrell Downs
RDF Radcliffe (Notts)
RDF Radcliffe-on-Trent
RDT Radlett
RAD Radley
RDR Radyr
RNF Rainford
RNM Rainham (Essex)
RAI Rainham (Kent)
RNM Rainham Essex
RAI Rainham Kent
RNH Rainhill
RAM Ramsgate
RGW Ramsgreave & Wilpshire
RAN Rannoch
RDU Rathdrum <Cie>
RMR Rathmore <Cie>
RAU Rauceby
RAV Ravenglass
RAV Ravenglass for Eskdale
RVB Ravensbourne
RVN Ravensthorpe
RWC Rawcliffe
RLG Rayleigh
RAY Raynes Park
RDG Reading
RDW Reading West
REC Rectory Road
RDB Redbridge
RDB Redbridge Hants
RBS Redcar British Steel
RCC Redcar Central
RCE Redcar East
RDN Reddish North
RDS Reddish South
RDC Redditch
RDH Redhill
RDA Redland
RED Redruth
REE Reedham (Norfolk)
RHM Reedham (Surrey)
REI Reigate
RTN Renton
RET Retford
RHI Rhiwbina
RIA Rhoose (Cardiff International Airport)
RIA Rhoose Cardiff International Airport
RHO Rhosneigr
RHL Rhyl
RHY Rhymney
RHD Ribblehead
RIL Rice Lane
RMD Richmond
RMK Richmond (Nth Yorks)
RMD Richmond London
RIC Rickmansworth
RDD Riddlesdown
RID Ridgmont
RDM Riding Mill
RCA Risca & Pontymister
RIS Rishton
RBR Robertsbridge
RHA Robin Hood Airport
ROB Roby
RCD Rochdale
ROC Roche
RTR Rochester
RFD Rochford
RFY Rock Ferry
ROG Rogart
ROR Rogerstone
ROL Rolleston
RMB Roman Bridge
RMF Romford
RML Romiley
ROM Romsey
REB Romsey Bus Station
ROO Roose
RCM Roscommon <Cie>
RCR Roscrea <Cie>
RSG Rose Grove
RSH Rose Hill Marple
RSB Rosslare Europort <Cie>
RSS Rosslare Strand <Cie>
ROS Rosyth
RMC Rotherham Central
RNR Roughton Road
RLN Rowlands Castle
ROW Rowley Regis
RYB Roy Bridge
RYN Roydon
RYS Royston
RUA Ruabon
RUF Rufford
RUG Rugby
RGT Rugeley Town
RGL Rugeley Trent Valley
RUN Runcorn
RUE Runcorn East
RKT Ruskington
RUS Ruswarp
RUT Rutherglen
RYR Ryde St Johns Road
RYD Ryde Esplanade
XRD Ryde Hoverport
RYP Ryde Pier Head
RYR Ryde St Johns Road
RRB Ryder Brow
RYE Rye
RYE Rye (Sussex)
RYH Rye House
SFD Salford Central
SLD Salford Crescent
SAF Salfords
SAF Salfords (Surrey)
SAH Salhouse
SAL Salisbury
SAE Saltaire
STS Saltash
SLB Saltburn
SLT Saltcoats
SAM Saltmarshe
SLW Salwick
SMC Sampford Courtenay
SNA Sandal & Agbrigg
SDB Sandbach
SNR Sanderstead
SDL Sandhills
SND Sandhurst
SND Sandhurst (Berks)
SDG Sandling
SAN Sandown
SDP Sandplace
XSA Sandringham
SAD Sandwell & Dudley
SDW Sandwich
SDY Sandy
SNK Sankey
SNK Sankey for Penketh
SQH Sanquhar
SRR Sarn
SDF Saundersfoot
SDR Saunderton
SAW Sawbridgeworth
SXY Saxilby
SAX Saxmundham
SCA Scarborough
SCT Scotscalder
SCH Scotstounhill
SCU Scunthorpe
SML Sea Mills
SEB Seaburn
SEF Seaford
SEF Seaford (Sussex)
SFL Seaforth & Litherland
SEA Seaham
SEM Seamer
SSC Seascale
SEC Seaton Carew
SRG Seer Green
SRG Seer Green & Jordans
SBY Selby
SRS Selhurst
SKK Selkirk (Bus)
SEL Sellafield
SEG Selling
SLY Selly Oak
SET Settle
SVK Seven Kings
SVS Seven Sisters
SEV Sevenoaks
SVB Severn Beach
STJ Severn Tunnel Junction
SFR Shalford
SFR Shalford (Surrey)
SHN Shanklin
SHA Shaw & Crompton
SHW Shawford
SHL Shawlands
SSS Sheerness-on-Sea
SHF Sheffield
SED Shelford
SED Shelford (Cambs)
SNF Shenfield
SEN Shenstone
SPB Shepherd's Bush
SPB Shepherds Bush
SPH Shepherds Well
SPY Shepley
SHP Shepperton
STH Shepreth
SHE Sherborne
SIE Sherburn-in-Elmet
SHM Sheringham
SLS Shettleston
SDM Shieldmuir
SFN Shifnal
SHD Shildon
SHI Shiplake
SHY Shipley
SHY Shipley (Yorks)
SPP Shippea Hill
SIP Shipton
SHB Shirebrook
SHH Shirehampton
SRO Shireoaks
SRL Shirley
SRY Shoeburyness
SHO Sholing
SEH Shoreham (Kent)
SSE Shoreham-by-Sea
SRT Shortlands
SHT Shotton
SHS Shotts
SHR Shrewsbury
SID Sidcup
SIL Sileby
SIC Silecroft
SLK Silkstone Common
SLV Silver Street
SVR Silverdale
SIN Singer
SIT Sittingbourne
SKG Skegness
SKE Skewen
SKI Skipton
SGR Slade Green
SWT Slaithwaite
SLA Slateford
SLR Sleaford
SLH Sleights
SLI Sligo <Cie>
SLO Slough
SMA Small Heath
SAB Smallbrook Junction
SGB Smethwick Galton Bridge
SMR Smethwick Rolfe Street
SMI Smitham
SMB Smithy Bridge
SNI Snaith
SDA Snodland
SWO Snowdown
SOR Sole Street
SOL Solihull
SYT Somerleyton
SAT South Acton
SBK South Bank
SBM South Bermondsey
SCY South Croydon
SES South Elmsall
SGN South Greenford
SGL South Gyle
SOH South Hampstead
SOK South Kenton
SMO South Merton
SOM South Milford
SRU South Ruislip
STO South Tottenham
SWS South Wigston
SOF South Woodham Ferrers
STL Southall
SOA Southampton Airport
SOA Southampton Airpt Parkway
SOU Southampton Central
SOB Southbourne
SBU Southbury
SEE Southease
SEZ Southease (Church By bus)
SOC Southend Central
SOE Southend East
SOV Southend Victoria
SMN Southminster
SOP Southport
SHV Southsea Hoverport
SLZ Southwell Norwood Gardens
SWK Southwick
SOW Sowerby Bridge
SPA Spalding
SBR Spean Bridge
SPI Spital
SPO Spondon
SPN Spooner Row
SRI Spring Road
SPR Springburn
SPF Springfield
SQU Squires Gate
SAC St Albans
SAA St Albans Abbey
SAO St Andrews (By Bus)
SAR St Andrews Road
SAS St Annes-on-Sea
SAS St Annes-on-the-Sea
SAU St Austell
SBS St Bees
SBF St Budeaux Ferry Road
SBV St Budeaux Victoria Road
SCR St Columb Road
SDN St Denys
SER St Erth
SGM St Germans
SNH St Helens Central
SHJ St Helens Junction
SIH St Helier
SIH St Helier (Surrey)
SIV St Ives (Cornwall)
SJP St James Park
SJP St James Park Exeter
SJS St James Street
SJS St James Street Walthamstow
SAJ St Johns
SKN St Keyne
SKN St Keyne Wishing Well Halt
SLQ St Leonards Warrior Square
SMG St Margarets (Gr London)
SMT St Margarets (Herts)
SMG St Margarets (London)
SMY St Mary Cray
STM St Michaels
SNO St Neots
STP St Pancras Domestic (London)
SPX St Pancras International
STZ St Peters
STI Stadium of Light
STA Stafford
SNS Staines
SLL Stallingborough
SYB Stalybridge
SMD Stamford
SMH Stamford Hill
SMD Stamford Lincs
SFO Stanford-le-Hope
SNT Stanlow & Thornton
SSD Stansted Airport
SST Stansted Mountfitchet
SPU Staplehurst
SRD Stapleton Road
SBE Starbeck
SCS Starcross
SVL Staveley
SVL Staveley (Cumbria)
SCF Stechford
SON Steeton & Silsden
SPS Stepps
SVG Stevenage
STV Stevenston
SWR Stewartby
STT Stewarton
STG Stirling
SPT Stockport
SKS Stocksfield
SSM Stocksmoor
STK Stockton
SKM Stoke Mandeville
SKW Stoke Newington
SOT Stoke-on-Trent
SNE Stone
SCG Stone Crossing
SGQ Stone Granville Square
SNE Stone Staffs
SBP Stonebridge Park
SOG Stonegate
STN Stonehaven
SHU Stonehouse
SNL Stoneleigh
SBJ Stourbridge Junction
SBT Stourbridge Town
SMK Stowmarket
STR Stranraer
SRA Stratford (London)
SAV Stratford-upon-Avon
STC Strathcarron
STW Strawberry Hill
STE Streatham
SRC Streatham Common
SRH Streatham Hill
SHC Streethouse
SRN Strines
STF Stromeferry
SOO Strood
SOO Strood (Kent)
STD Stroud
STD Stroud (Gloucs)
STU Sturry
SYA Styal
SUY Sudbury
SUD Sudbury & Harrow Road
SUY Sudbury (Suffolk)
SDH Sudbury Hill Harrow
SUG Sugar Loaf
SUG Sugar Loaf Halt
SUM Summerston
SUU Sunbury
SUN Sunderland
SUP Sundridge Park
SNG Sunningdale
SNY Sunnymeads
SUR Surbiton
SUO Sutton (Surrey)
SUT Sutton Coldfield
SUC Sutton Common
SPK Sutton Parkway
SWB Swaffham (Coach)
SWL Swale
SAY Swanley
SWM Swanscombe
SWA Swansea
SNW Swanwick
SWY Sway
SWG Swaythling
SWD Swinderby
SWI Swindon
SWI Swindon (Wilts)
SWE Swineshead
SNN Swinton (Gr Manchester)
SNN Swinton (Manchester)
SWN Swinton (South Yorks)
SWN Swinton (Yorks)
SYD Sydenham
SYD Sydenham (London)
SYH Sydenham Hill
SYL Syon Lane
SYS Syston
TAC Tackley
TAD Tadworth
TTA Tadworth (The Avenue By bus)
TAF Taffs Well
TAI Tain
TLC Tal-y-Cafn
TAL Talsarnau
TLB Talybont
TAB Tame Bridge Parkway
TAM Tamworth
TYB Tan-Y-Bwlch (Ffestiniog Railway)
TAP Taplow
TAT Tattenham Corner
TAU Taunton
XCV Tavistock (By Bus)
TAY Taynuilt
TED Teddington
TVA Tees Valley Airport
TEA Tees-side Airport
TEA Teesside Airport
TGM Teignmouth
TFC Telford Central
TMC Templecombe
TEM Templemore <Cie>
TEN Tenby
TEY Teynham
THD Thames Ditton
THA Thatcham
THH Thatto Heath
THW The Hawthorns
TLK The Lakes
TLK The Lakes (Warks)
THE Theale
TEO Theobalds Grove
TTF Thetford
THI Thirsk
THM Thomastown <Cie>
TBY Thornaby
TNN Thorne North
TNS Thorne South
THO Thornford
THB Thornliebank
TNA Thornton Abbey
TTH Thornton Heath
THT Thorntonhall
TPB Thorpe Bay
TPC Thorpe Culvert
TLS Thorpe-le-Soken
TBD Three Bridges
TOK Three Oaks
THU Thurgarton
TUS Thurles <Cie>
THC Thurnscoe
THS Thurso
TRS Thurston
TBR Tilbury Riverside
TIL Tilbury Town
THL Tile Hill
TLH Tilehurst
TPY Tipperary <Cie>
TIP Tipton
TIR Tir-Phil
TIS Tisbury
TVP Tiverton Parkway
TOD Todmorden
TOL Tolworth
TPN Ton Pentre
TON Tonbridge
TDU Tondu
TNF Tonfanau
TNP Tonypandy
TOO Tooting
TOP Topsham
TQY Torquay
TRR Torre
TOT Totnes
TOM Tottenham Hale
TTN Totton
TWN Town Green
TRA Trafford Park
TRL Tralee <Cie>
TRF Trefforest
TRE Trefforest Estate
TRH Trehafod
TRB Treherbert
TRY Treorchy
TRM Trimley
TRI Tring
TRD Troed-y-Rhiw
TRD Troed-y-rhiw
TRN Troon
TRO Trowbridge
TRU Truro
TUM Tullamore <Cie>
TUL Tulloch
TUH Tulse Hill
TBW Tunbridge Wells
TUR Turkey Street
TUT Tutbury & Hatton
TWI Twickenham
TWY Twyford
TYC Ty Croes
TGS Ty Glas
TYG Tygwyn
TYL Tyndrum Lower
TYS Tyseley
TYW Tywyn
UCK Uckfield
UDD Uddingston
ULC Ulceby
ULP Ullapool (By Bus)
ULL Ulleskelf
ULV Ulverston
UMB Umberleigh
UNI University
UNI University (Birmingham)
UHA Uphall
UPL Upholland
UPM Upminster
UPH Upper Halliford
UHL Upper Holloway
UTY Upper Tyndrum
UWL Upper Warlingham
UPT Upton
UPT Upton (Merseyside)
UPW Upwey
URM Urmston
UTT Uttoxeter
VAL Valley
VXH Vauxhall
VIC Victoria (London)
VIR Virginia Water
JJJ Vt Exp Cars Z1
JJK Vt Exp Cars Z2
JJL Vt Exp Cars Z3
WDO Waddon
WAD Wadhurst
WFL Wainfleet
WKK Wakefield Kirkgate
WKF Wakefield Westgate
WKD Walkden
WLG Wallasey Grove Road
WLV Wallasey Village
WLT Wallington
WAF Wallyford
WAM Walmer
WSL Walsall
WDN Walsden
WLC Waltham Cross
WHC Walthamstow Central
WMW Walthamstow Queen's Road
WMW Walthamstow Queens Road
WAO Walton (Merseyside)
WON Walton on the Naze
WAL Walton-on-Thames
WON Walton-on-the-Naze
WAN Wanborough
WSW Wandsworth Common
WWR Wandsworth Road
WNT Wandsworth Town
WNP Wanstead Park
WBL Warblington
WAR Ware
WAR Ware (Herts)
WRM Wareham
WRM Wareham (Dorset)
WGV Wargrave
WMN Warminster
WNH Warnham
WBQ Warrington Bank Quay
WAC Warrington Central
WRW Warwick
WRP Warwick Parkway
WTO Water Orton
WBC Waterbeach
WFD Waterford <Cie>
WTR Wateringbury
WAT Waterloo (London)
WLO Waterloo (Merseyside)
WAE Waterloo East (London)
WFH Watford High Street
WFJ Watford Junction
WFN Watford North
WTG Watlington
WAS Watton-at-Stone
WNG Waun-Gron Park
WAV Wavertree Tech Park
WAV Wavertree Technology Park
WED Wedgwood
WER Wedgwood Old Road
WEE Weeley
WET Weeton
WMG Welham Green
WLI Welling
WEL Wellingborough
WLN Wellington (Shropshire)
WEB Wellington Bridge <Cie>
WLP Welshpool
WGC Welwyn Garden City
WLW Welwyn North
WEM Wem
WMB Wembley Central
WCX Wembley Stadium
WCS Wembley Stadium (By Bus)
WMS Wemyss Bay
WND Wendover
WNN Wennington
WSA West Allerton
WBP West Brompton
WBY West Byfleet
WCL West Calder
WTW West Cowes
WCY West Croydon
WDT West Drayton
WDU West Dulwich
WEA West Ealing
WEH West Ham
WHD West Hampstead
WHP West Hampstead Thameslink
WHR West Horndon
WKB West Kilbride
WKI West Kirby
WMA West Malling
WNW West Norwood
WRU West Ruislip
WRN West Runton
WLD West St Leonards
WSU West Sutton
WWI West Wickham
WWO West Worthing
WSB Westbury
WSB Westbury (Wilts)
WCF Westcliff
WCB Westcombe Park
WHA Westenhanger
WTA Wester Hailes
WFI Westerfield
WES Westerton
WGA Westgate-on-Sea
WHG Westhoughton
WNM Weston Milton
WSM Weston-super-Mare
WPT Westport <Cie>
WRL Wetheral
WXF Wexford <Cie>
WYB Weybridge
WEY Weymouth
WBR Whaley Bridge
WHE Whalley
WHE Whalley (Lancs)
WTS Whatstandwell
WFF Whifflet
WHM Whimple
WNL Whinhill
WHN Whiston
WTB Whitby
WTZ Whitby Bus
WHT Whitchurch (Cardiff)
WHT Whitchurch (Glamorgan)
WCH Whitchurch (Hants)
WTC Whitchurch (Shrops)
WTC Whitchurch (Shropshire)
WHL White Hart Lane
WNY White Notley
WCR Whitecraigs
WTH Whitehaven
WTL Whitland
WBD Whitley Bridge
WTE Whitlocks End
WHI Whitstable
WLE Whittlesea
WLF Whittlesford Parkway
WTN Whitton
WTN Whitton London
WWL Whitwell
WWL Whitwell (Derbys)
WHY Whyteleafe
WHS Whyteleafe South
WCK Wick
WIC Wickford
WCM Wickham Market
WKL Wicklow <Cie>
WDD Widdrington
WID Widnes
WMR Widney Manor
WGN Wigan North Western
WGW Wigan Wallgate
WGT Wigton
WMI Wildmill
WIJ Willesden Junction
WLM Williamwood
WIL Willington
WMC Wilmcote
WML Wilmslow
WNE Wilnecote
WNE Wilnecote (Staffs)
WIM Wimbledon
WBO Wimbledon Chase
WSE Winchelsea
WIN Winchester
WNF Winchfield
WIH Winchmore Hill
WDM Windermere
WNC Windsor & Eton Central
WNR Windsor & Eton Riverside
WNS Winnersh
WTI Winnersh Triangle
WSF Winsford
WIS Wisbech Bus Station
WSH Wishaw
WTM Witham
WTY Witley
WTT Witton
WTT Witton West Midlands
WVF Wivelsfield
WIV Wivenhoe
WOB Woburn Sands
WOK Woking
WKM Wokingham
WOH Woldingham
WVH Wolverhampton
WOL Wolverton
WOM Wombwell
WDE Wood End
WST Wood Street
WDB Woodbridge
WGR Woodgrange Park
WDL Woodhall
WDH Woodhouse
WLA Woodlawn <Cie>
WDS Woodlesford
WLY Woodley
WME Woodmansterne
WSR Woodsmoor
WOO Wool
WLS Woolston
WWA Woolwich Arsenal
WWD Woolwich Dockyard
WWW Wooten Wawen
WWW Wootton Wawen
WOF Worcester Foregate Street
WCP Worcester Park
WOS Worcester Shrub Hill
WKG Workington
WOX Workington Bus Station
WRK Worksop
WOR Worle
WPL Worplesdon
WRT Worstead
WRH Worthing
WRB Wrabness
WRY Wraysbury
WRE Wrenbury
WRS Wressle
WXC Wrexham Central
WRX Wrexham General
WYE Wye
WYM Wylam
WYL Wylde Green
WMD Wymondham
WYT Wythall
YAL Yalding
YRD Yardley Wood
YRM Yarm
YMH Yarmouth (Isle Of Wight)
YAE Yate
YAT Yatton
YEO Yeoford
YVJ Yeovil Junction
YVP Yeovil Pen Mill
YET Yetminster
YNW Ynyswen
YOK Yoker
YRK York
YRT Yorton
YSM Ystrad Mynach
YSR Ystrad Rhondda
