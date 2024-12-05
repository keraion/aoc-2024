create or replace table day03 as
from read_csv(
    'data/day03.txt', 
    header = false,
    null_padding=true,
    delim = ''
);

with multiplied as (
    select
        unnest(regexp_extract_all(column0, 'mul\((\d{1,3}),(\d{1,3})\)', 1))::int 
        * unnest(regexp_extract_all(column0, 'mul\((\d{1,3}),(\d{1,3})\)', 2))::int as mul
    from day03
)

select sum(mul)
from multiplied
;

with multiplied as (
    select
        unnest(regexp_extract_all(column0, '(do(?:n''t)?\(\))|mul\((\d{1,3}),(\d{1,3})\)', 1)) as do_or_dont,
        unnest(regexp_extract_all(column0, '(do(?:n''t)?\(\))|mul\((\d{1,3}),(\d{1,3})\)', 2)) as first_mul,
        unnest(regexp_extract_all(column0, '(do(?:n''t)?\(\))|mul\((\d{1,3}),(\d{1,3})\)', 3)) as sec_mul,
    from day03
),

do_list as (
    select
        row_number() over () as rn,
        coalesce(do_or_dont, lag(do_or_dont ignore nulls) over (), 'do()') as it_do,
        first_mul::int * sec_mul::int as mul
    from multiplied
)

select sum(mul)
from do_list
where it_do = 'do()'
;