-- Import Input
create or replace table day04 as
from read_csv(
    'data/day04.txt', 
    header = false,
    null_padding=true,
    delim = ''
);

-- Part 1

with split_letters as (
    select 
        /* 
            create a row number
            create a column number
            unnest each letter into an individual row
            get num_columns for the reverse top-left to bottom-right
        */
        *,
        row_number() over () as rn,
        generate_subscripts(split(column0, ''), 1) as cn,
        unnest(split(column0, '')) as letter,
        len(column0) as num_columns
    from day04
),

row_matches as (
    /*
        Extract each occurence of 'XMAS' or 'SAMX', regexp_extract_all 
        gives us an array to count, but we can't have overlapping 
        matching so check each individually.
    */
    select sum(
        len(regexp_extract_all(column0, 'XMAS') 
        + regexp_extract_all(column0, 'SAMX'))
     ) as row_count
    from day04
),

column_letters as (
    /*
        Transpose rows to columns.
    */
    select 
        cn,
        string_agg(letter, '' order by rn) as column0,
    from split_letters
    group by cn
),

column_matches as (
    /*
        Again, extract each occurence of 'XMAS' or 'SAMX', regexp_extract_all 
        gives us an array to count, but we can't have overlapping 
        matching so check each individually, but with columns.
    */
    select
        sum(len(regexp_extract_all(column0, 'XMAS') 
        + regexp_extract_all(column0, 'SAMX'))) as col_count
    from column_letters
),

diag1_letters as (
    /*
        create an index that groups all the bottom-left to top-right diagonals together
        make a string of each diagonal.
    */
    select 
        cn + rn,
        string_agg(letter, '' order by rn) as column0,
    from split_letters
    group by cn + rn
),

diag1_matches as (
    /*
        Again, extract each occurence of 'XMAS' or 'SAMX', regexp_extract_all 
        gives us an array to count, but we can't have overlapping 
        matching so check each individually, but with bl-tr string.
    */
    select
        sum(len(regexp_extract_all(column0, 'XMAS') 
        + regexp_extract_all(column0, 'SAMX'))) as diag1_count
    from diag1_letters
),

diag2_letters as (
    /*
        create an index that groups all the top-left to bottom-right diagonals together
        make a string of each diagonal.
    */
    select 
        num_columns - cn + rn as grp,
        string_agg(letter, '' order by rn) as column0,
    from split_letters
    group by num_columns - cn + rn
),

diag2_matches as (
    /*
        Again, extract each occurence of 'XMAS' or 'SAMX', regexp_extract_all 
        gives us an array to count, but we can't have overlapping 
        matching so check each individually, but with tl-br string.
    */
    select
        sum(len(regexp_extract_all(column0, 'XMAS') 
        + regexp_extract_all(column0, 'SAMX'))) as diag2_count
    from diag2_letters
),

all_matches as (
    -- Combine the counts
    from row_matches
    union all
    from column_matches
    union all
    from diag1_matches
    union all
    from diag2_matches
)

select SUM(row_count) as total_count
from all_matches
;

-- Part 2
with split_letters as (
    /* 
        create a row number
        create a column number
        unnest each letter into an individual row
        get num_columns for the reverse top-left to bottom-right
    */
    select 
        *,
        row_number() over () as rn,
        generate_subscripts(split(column0, ''), 1) as cn,
        unnest(split(column0, '')) as letter,
        len(column0) as num_columns
    from day04
),

diag1_letters as (
    /*
        create an index that groups all the bottom-left to top-right diagonals together
        make an array of structs that include the letter, row position, and column position
    */
    select
        cn + rn as idx,
        array_agg(struct_pack(
            ltr := letter,
            r := rn,
            c := cn
         ) order by rn) as ltr_arr,
    from split_letters
    group by cn + rn
),

diag2_letters as (
    /*
        create an index that groups all the top-left to bottom-right diagonals together
        make an array of structs that include the letter, row position, and column position
    */
    select 
        (num_columns + 1 - cn) + rn as idx,
        array_agg(
            struct_pack(
                ltr := letter,
                r := rn,
                c := cn
            ) 
            order by rn
        ) as ltr_arr,
    from split_letters
    group by idx
),

diag1_matches as (
    /*
        What this does:
        list_zip: We need three letters in a row, zip the same list from the 1st, 2nd, 
            and 3rd position, truncate to get only full lists with all three.
        list_transform: make a struct that concats the three letter together and note 
            the middle letter's position (row and column).
        list_filter: only include records that are 'MAS' or 'SAM'.
        unnest, recursively: split out the arrays we made and make the structs into
            their columns.
    */
    select
        unnest(
            list_filter(
                list_transform(
                    list_zip(ltr_arr, ltr_arr[2:], ltr_arr[3:], truncate := true),
                    (x, i) -> struct_pack(
                        c := x[2].c,
                        r := x[2].r,
                        val := x[1].ltr || x[2].ltr || x[3].ltr
                    )
                ),
                x -> x.val in ('MAS', 'SAM')
            ),
            recursive := true
        ) as mas_loc
    from diag1_letters
),

diag2_matches as (
    -- same steps as diag1_matches
    select
        unnest(
            list_filter(
                list_transform(
                    list_zip(ltr_arr, ltr_arr[2:], ltr_arr[3:], truncate := true),
                    (x, i) -> struct_pack(
                        c := x[2].c,
                        r := x[2].r,
                        val := x[1].ltr || x[2].ltr || x[3].ltr
                    )
                ),
                x -> x.val in ('MAS', 'SAM')
            ),
            recursive := true
        ) as mas_loc
    from diag2_letters
)

/*
    Get all the matching middle positions with a join. The row and column will
    be the same position and we know they are either 'MAS' or 'SAM' to make the "X"
*/
select COUNT(*) as answer
from diag1_matches as d1
inner join diag2_matches as d2
on d1.c = d2.c
and d1.r = d2.r
;