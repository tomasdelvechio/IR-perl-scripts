#!/usr/bin/perl
system(clear);

#use encoding 'utf8';
use lib('lib/');
use IR::General5;

#################
### Variables ###  
#################

$directorio_coleccion = './colecciones/donq';

$archivo_terminos = './salidas/ejercicio5/terminos.txt';

$archivo_estadisticas = './salidas/ejercicio5/estadisticas.txt';

$archivo_frecuencias = './salidas/ejercicio5/frecuencias.txt';

#####################
### Procesamiento ###
#####################

# Abrimos el directorio
opendir (dir, $directorio_coleccion) or die "No se pudo abrir";

# Recorremos cada archivo
while( $file = readdir( dir ) ) {
    
    # Ignoramos las referencias de unix a si mismo y al padre
    if( $file ne "." and $file ne ".." ) {
        
        # Abre el archivo
        open (IN,"$directorio_coleccion/$file");
        binmode (IN, "utf8");
        print "Analizando archivo: $file\n";
        
        $estadisticas{"Cantidad de documentos procesados"} += 1;
        
        # Para cada linea del archivo
        while( $linea = <IN> ) {
            
            # Preparamos la linea para generar los token
            $linea = preparar_linea($linea);
            #print $linea;
            # Tokenizamos la linea
            @tokens = tokenizar($linea);
            
            # Procesamos cada uno de los tokens de la linea
            foreach $palabra ( @tokens ) {
                
                $palabra = limpiar_token($palabra);
                
                if ( token_valido( $palabra ) ) {
                    
                    # Calculo del TF
                    $frecuencias{$palabra}{"TF"} += 1;
                    #print "$palabra";
                    # Recogemos estadisticas de cantidad de terminos por documento
                    $estadisticas{"cantidad_terminos_documentos"}{$file}{$palabra} += 1;
                    
                    # Para despues calcular el DF
                    $frecuencias{$palabra}{$file} = 1;
                    
                }
                
            }
            
        }
        
        close(IN);
    
    }

}

#########################
### Pos-procesamiento ###
#########################

# Armamos un arreglo con las claves ordenadas por la TF en forma descendente, para el punto c) del TP
@terminos_ordenados_por_frecuencias = sort { $frecuencias{$b}{"TF"} <=> $frecuencias{$a}{"TF"} } keys %frecuencias;

$estadisticas{"Cantidad de terminos extraidos"} = scalar(keys %frecuencias);

$estadisticas{"Promedio de terminos por documento"} =  int($estadisticas{"Cantidad de terminos extraidos"} / $estadisticas{"Cantidad de documentos procesados"});

# Calculo del DF
foreach $termino (keys %frecuencias) {
    
    $df = scalar(keys %{$frecuencias{$termino}});
    
    # Ignoramos el indice TF que no corresponde
    $df = $df - 1;
    
    $estadisticas{"Largo promedio de un termino"} += length($termino);
    
    $frecuencias{$termino}{"DF"} = $df;
    
    # Calculamos la cantidad de documentos con TF = 1
    
    if ( $frecuencias{$termino}{"TF"} == 1 ) {
        
        $estadisticas{"Cantidad de terminos con frecuencia 1 en la coleccion"} += 1;
        
    }
    
}

$estadisticas{"Largo promedio de un termino"} = int($estadisticas{"Largo promedio de un termino"} / $estadisticas{"Cantidad de terminos extraidos"});

# Busco documento mas corto y mas largo
$estadisticas{"Cantidad de terminos del documento mas largo"} = 0;
$estadisticas{"Cantidad de terminos del documento mas corto"} = $estadisticas{"Cantidad de terminos extraidos"};

foreach $documento (keys %{$estadisticas{"cantidad_terminos_documentos"}}) {
    
    # Calculamos la cantidad de terminos para el documento actual
    $cantidad_terminos_documento = scalar(keys %{$estadisticas{"cantidad_terminos_documentos"}{$documento}});
    
    if( $estadisticas{"Cantidad de terminos del documento mas largo"} < $cantidad_terminos_documento ) {
        
        $estadisticas{"Cantidad de terminos del documento mas largo"} = $cantidad_terminos_documento;
        $estadisticas{"Nombre del documento mas largo"} = $documento;
        
    }
    
    if( $estadisticas{"Cantidad de terminos del documento mas corto"} > $cantidad_terminos_documento ) {
        
        $estadisticas{"Cantidad de terminos del documento mas corto"} = $cantidad_terminos_documento;
        $estadisticas{"Nombre del documento mas corto"} = $documento;
        
    }
    
}

###############
### SALIDAS ###
###############

### TERMINOS.TXT

# Abrimos el archivo de salida de terminos
open(OUT, ">$archivo_terminos");

# Teniendo procesada toda la coleccion
foreach $termino ( sort( keys %frecuencias ) ) {
    
    #print OUT "Termino: $termino TF: $frecuencias{$termino}{'TF'}  DF: $frecuencias{$termino}{'DF'}\n";
    $salida = sprintf("Termino: %-50s TF: %-5s  DF: %s\n", $termino, $frecuencias{$termino}{"TF"}, $frecuencias{$termino}{"DF"});
    #print $salida;
    #printf(OUT "Termino: %-50s TF: %-5s  DF: %s\n", $termino, $frecuencias{$termino}{"TF"}, $frecuencias{$termino}{"DF"});
    print OUT $salida;
    
}

close(OUT);

### ESTADISTICAS.TXT

# Abrimos el archivo
open(OUT, ">$archivo_estadisticas");

print OUT "Estadisticas de la coleccion:\n";
print OUT "=============================\n";
print OUT "Cantidad de documentos procesados: $estadisticas{'Cantidad de documentos procesados'}\n";
print OUT "Cantidad de terminos extraidos: $estadisticas{'Cantidad de terminos extraidos'}\n";
print OUT "Promedio de terminos por documento: $estadisticas{'Promedio de terminos por documento'}\n";
print OUT "Largo promedio de un termino: $estadisticas{'Largo promedio de un termino'}\n";
print OUT "Nombre del documento mas largo: $estadisticas{'Nombre del documento mas largo'}\n";
print OUT "Cantidad de terminos del documento mas largo: $estadisticas{'Cantidad de terminos del documento mas largo'}\n";
print OUT "Nombre del documento mas corto: $estadisticas{'Nombre del documento mas corto'}\n";
print OUT "Cantidad de terminos del documento mas corto: $estadisticas{'Cantidad de terminos del documento mas corto'}\n";
print OUT "Cantidad de terminos con frecuencia 1 en la coleccion: $estadisticas{'Cantidad de terminos con frecuencia 1 en la coleccion'}\n";
print OUT "\n";

close(OUT);

### FRECUENCIAS.TXT

# Abrimos el archivo
open(OUT, ">$archivo_frecuencias");

print OUT "Los 10 terminos mas frencuentes de la coleccion:\n";
print OUT "================================================\n";

for ($i=0; $i<=9; $i++)
{   
    $elem = @terminos_ordenados_por_frecuencias[$i];
    print OUT "$elem: $frecuencias{$elem}{'TF'}\n";
}

print OUT "\nLos 10 terminos menos frencuentes de la coleccion:\n";
print OUT "==================================================\n";

$desde = scalar(@terminos_ordenados_por_frecuencia) - 10;
$hasta = scalar(@terminos_ordenados_por_frecuencia) - 1;

for ($i=$desde; $i<=$hasta; $i++)
{   
    $elem = @terminos_ordenados_por_frecuencias[$i];
    print OUT "$elem: $frecuencias{$elem}{'TF'}\n";
}

close(OUT);

