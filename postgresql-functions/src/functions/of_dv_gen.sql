CREATE OR REPLACE FUNCTION public.of_dv_gen(text)
 RETURNS text
 LANGUAGE plpgsql
AS $function$
DECLARE
  d     TEXT    :=''; -- cadena de digitos
  suma  INTEGER := 0;
  impar BOOLEAN := TRUE;
  n     INTEGER := 0;
  i     INTEGER;
  c     TEXT   ;

BEGIN
  --d := of_solo_numeros($1)::NUMERIC::TEXT; -- Los ceros a la izquierda no cuentan
  IF (trim($1) IS NULL OR length(trim($1))=0) THEN
    RETURN '';
  END IF;

  -- DGZZH 11/08/2016 Acepta caracteres alfanuméricos
  -- Convertidor de caracteres alfanuméricos a numericos
  FOR i IN 1..length($1) LOOP
    c  := substring($1,i,1);
    IF c NOT IN ('1','2','3','4','5','6','7','8','9','0') THEN
      c = upper(c);
      CASE WHEN c IN ('A','B','C') THEN c := '2';
           WHEN c IN ('D','E','F') THEN c := '3';
           WHEN c IN ('G','H','I') THEN c := '4';
           WHEN c IN ('J','K','L') THEN c := '5';
           WHEN c IN ('M','N','O') THEN c := '6';
           WHEN c IN ('P','Q','R') THEN c := '7';
           WHEN c IN ('S','T','U') THEN c := '8';
           WHEN c IN ('V','W','X') THEN c := '9';
           WHEN c IN ('Y','Z'    ) THEN c := '0';
           END CASE;
      d := d || c;
    ELSE
      d := d || c;
    END IF;
  END LOOP;

  FOR i IN REVERSE length(d)..1 LOOP
    n := substring(d,i,1)::INTEGER;
    IF (impar) THEN
      IF ((n * 2) >= 10) THEN
        suma := suma + ((n * 2) - 9);
      ELSE
        suma := suma + (n * 2);
      END IF;
    ELSE
      suma := suma + n;
    END IF;
    impar := NOT impar;
  END LOOP;

  n := 10 - (suma % 10);
  IF (n = 10) THEN
    n := 0;
  END IF;

  RETURN n;
END;$function$