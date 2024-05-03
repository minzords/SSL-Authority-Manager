#!/usr/bin/perl

use strict;
use warnings;

# Vérification des arguments
if (@ARGV < 1) {
    die "Usage: $0 <domain>\n";
}

my $domain = $ARGV[0];  # Domaine fourni comme argument

# Configuration des chemins et noms de fichiers
my $days_valid = 1000;  # Durée de validité du certificat
my $ca_key = "/opt/SSL-Authority/CA/CA.key";  # Clé privée de l'autorité de certification
my $ca_cert = "/opt/SSL-Authority/CA/CA.crt";  # Certificat de l'autorité de certification
my $server_key = "$domain.key";  # Clé privée du serveur avec extension .key
my $server_csr = "$domain.csr";  # Demande de signature de certificat (CSR)
my $server_cert = "$domain.crt";  # Certificat signé du serveur
my $extfile = "$domain.ext";

# Création de la clé privée du serveur
system("openssl", "genrsa", "-out", $server_key, "4096");

# Création de la CSR pour le serveur
system("openssl", "req", "-new", "-key", $server_key, "-out", $server_csr,
       "-subj", "/C=FR/ST=Bretagne/L=Rennes/O=Minzord/OU=AdminSys/CN=$domain");

# Contenu du fichier d'extension
my $ext_content = <<"EOF";
authorityKeyIdentifier=keyid,issuer
basicConstraints=CA:FALSE
keyUsage = digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
subjectAltName = \@alt_names

[alt_names]
DNS.1 = $domain
EOF

# Ouvrir le fichier en mode écriture
open(my $fh, '>', $extfile) or die "Could not open file '$extfile' $!";

# Écrire le contenu dans le fichier
print $fh $ext_content;

# Fermer le fichier
close $fh;


# Signature du certificat du serveur par l'autorité de certification
system("openssl", "x509", "-req",
       "-in", $server_csr,
       "-CA", $ca_cert,
       "-CAkey", $ca_key,
       "-CAcreateserial",
       "-out", $server_cert,
       "-days", "10000",
       "-sha256",
       "-extfile", $extfile);

# Affichage du certificat signé
print "Certificat signé pour $domain\n";
