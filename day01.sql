create or replace table day01 as
from read_csv(
    'data/day01.txt', 
    header = false,
    delim = ' '
);

/* Part 1 */
with ordered_list as (
    select 
        column0 as l1,
        column3 as l2,
        row_number() over (order by column0) as c1,
        row_number() over (order by column3) as c2,
    from day01
)

select sum(abs(a.l1 - b.l2)) as answer
from ordered_list as a
inner join ordered_list as b
on a.c1 = b.c2
;

/* Part 2 */
with l2_count as (
    select 
        column3 as l2,
        count(*) as occurences
    from day01
    group by column3
)

select sum(column0 * occurences) as answer
from day01 as a
inner join l2_count as b
on a.column0 = b.l2
;
