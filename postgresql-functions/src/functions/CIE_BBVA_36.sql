CREATE OR REPLACE FUNCTION CIE_BBVA_36(TEXT)
 RETURNS TEXT AS $$ 
DECLARE
    ref         TEXT    :=($1);
    c           TEXT    ;
    odd         BOOLEAN :=TRUE;
    ref_txt     TEXT    :='';
    n           INTEGER := 0;
BEGIN
    IF (trim(ref) IS NULL OR length(trim(ref)) = 0) THEN
        RETURN ''
    END IF;

/*
1)  Se le asigna a cada letra un valor de acuerdo a la tabla, para ser reemplazada
    en la referencia.
*/

    -- LOOP VARIABLE IN  REVERSE ONE TO ONE CHARACTER
    FOR i IN REVERSE length(ref)..1 LOOP
        -- GET CHARACTER TO VARIABLE i AS INTEGER
        c   :=  substring(ref, i, 1);
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
            ref_txt := ref_txt || c;
        ELSE
            ref_txt := ref_txt || c;
        END IF;
    END LOOP;

/*
2)  Se toman las nuevas posiciones y se les asigna un valor ponderador 2 y 1
    derecha a izquierda sucesivamente.
*/

    FOR i IN REVERSE length(ref_txt)..1 LOOP
/*
3)  Se multiplican los digitos de referencia por sus ponderadores:
    Si el resultado de la multiplicación 
*/
        n := substring(ref_txt,i,1)::INTEGER;

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
END;
$$ LANGUAGE plpgsql;