CREATE OR REPLACE FUNCTION CIE_BBVA_00 (TEXT)
 RETURNS TEXT AS $$
DECLARE
    ref         TEXT    :=($1);
    c           TEXT;
    impar       BOOLEAN := TRUE;
    val_sum     INTEGER := 0;
    aux         TEXT    ; -- NUMBER TWO DIGITS TYPE TEXT
    n           TEXT    ; -- CHARACTER TO NUMBER TWO DIGITS
    var         INTEGER ; -- SUM OF NUMBER TWO DIGITS
    quotient    INTEGER ; -- QUOTIENT
    residue     INTEGER ; -- RESIDUE
    dv          INTEGER ; -- VALUE OF 10 SUB RESIDUE
BEGIN
    -- VALIDATE DATA TEXT IF IS NULL OR CAONTAINS SPACES
    IF (trim(ref) IS NULL OR length(trim(ref))=0) THEN
        RETURN '';
    ELSE

/*  
1)  De derecha a izquierda se van multiplicando cada uno de los digítos por los números 2 y 1, siempre
    inciando la secuencia con el número 2 aun cuando el número a multiplicar sea 0 deberá tomarse en
    cuenta. Si el resultado de la multiplicación es mayor a 9, se deberán sumar las unidades y las decenas,
    de tal forma que solo se tenga com resultado un número menor o igual a 0. 
2)  Se suman todos los resultados de las mutliplicaciones del punto 1.
*/

        -- LLOP VARIABLE IN REVERSE ONE TO ONE CHARACTER
        FOR i IN REVERSE length(ref)..1 LOOP
            -- GET CHARACTER TO VARIABLE
            c := substring(ref,i,1)::INTEGER;
            -- IF THE NUMBER IS EVEN MULTIPLY BY 2
            IF (impar) THEN
                -- IF THE PRODUCT IS GREATER THAN 9 THEN ADD THE DIGITS
                IF (c::INTEGER * 2) > 9 THEN 
                    -- VAR TO STORE SUM OF THE DIGITS, RESTORE THE VALUE
                    var := 0;
                    -- CONVERT VALUE OF SUM IN TEXT
                    aux := (c::INTEGER * 2)::TEXT;
                    -- ADD THE TWO DIGITS OF THE PRODUCT VALUE
                    var := substring(aux,1,1)::INTEGER + substring(aux,2,1)::INTEGER;
                    -- SET VALUE OF SUM IN VARIABLE
                    -- RAISE NOTICE 'SUMA DE DOS DIGITOS ANTERIORES: %', var;
                    val_sum := val_sum + var;
                -- IF THE NUMBER IS NOT GREATHER THEN 9 ADD THE PRODUCT VALUE TO VAR
                ELSE
                    val_sum := val_sum + (c::INTEGER * 2);
                END IF;
                -- RAISE NOTICE '(%) * (2) = %', c, (c::INTEGER * 2);
            ELSE
                -- ADD THE VALUE OF SUM VARIABLE -> IS NOT NUMBER MORE THAN 9
                val_sum := val_sum + (c::INTEGER * 1);
                -- RAISE NOTICE '(%) * (1) = %', c, (c::INTEGER * 1);
            END IF;
            -- SET NOT THE VARIABLE
            impar := NOT impar;
            -- RAISE NOTICE '% -> %', val_sum::TEXT, impar::TEXT;
        END LOOP;

/*
3)  El resultado de la suma indicada en el punto 2 se divide entre 10 y se toma el residuo.
*/
        -- RAISE NOTICE '            %', val_sum;
        -- WE DIVIDE THE RESULT OF THE SUM BY 10
        quotient := (val_sum / 10)::INTEGER; 
        -- RAISE NOTICE 'QUOTIENT: %', quotient;
        -- VALUE OF RESIDUE
        residue := val_sum % 10;
        -- RAISE NOTICE 'RESIUDUE: %', residue;

/*
4)  El residuo obtenido del punto anterior se restará al valor 10.
*/

        -- RESIDUE OBTAINED FROM THE PREVIOUS POINT WILL BE SUBTRACTED FROM THE VALUE OF 10
        IF residue > 0 THEN
            dv := 10 - residue;
        ELSE
            dv := 0;
        END IF;
        -- RAISE NOTICE '10 - %  -> (RESIDUE): %',residue, dv;

        RETURN dv::TEXT;
    END IF;
END;
$$ LANGUAGE plpgsql;