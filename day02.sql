create or replace table day02 as
from read_csv(
    'data/day02.txt', 
    header = false,
    null_padding=true,
    delim = ''
);

with int_list as (
    select string_split(column0, ' ')::INT[] as l1
    from day02
),

magnitude as (
    select 
        l1,
        list_min(list_transform(l1, (x, i) -> x - l1[i + 1])) as lst,
        list_max(list_transform(l1, (x, i) -> x - l1[i + 1])) as gt,
    from int_list
)

select sum((sign(lst) = sign(gt) and abs(lst) between 1 and 3 and abs(gt) between 1 and 3)::int) as answer
from magnitude;

with int_list as (
    select 
        row_number() over () as rn,
        string_split(column0, ' ')::INT[] as l1,
        generate_subscripts(l1, 1) as subs,
    from day02
),

magnitude as (
    select
        rn,
        l1,
        subs,
        list_filter(l1, (x, i) -> subs <> i) as l2,
        list_min(list_transform(l1, (x, i) -> x - l1[i + 1])) as lst,
        list_max(list_transform(l1, (x, i) -> x - l1[i + 1])) as gt,
        list_min(list_transform(l2, (x, i) -> x - l2[i + 1])) as lst_2,
        list_max(list_transform(l2, (x, i) -> x - l2[i + 1])) as gt_2,
    from int_list
),

checks as (
    select
        rn, 
        max(sign(lst) = sign(gt) and abs(lst) between 1 and 3 and abs(gt) between 1 and 3)::int as answer,
        max(sign(lst_2) = sign(gt_2) and abs(lst_2) between 1 and 3 and abs(gt_2) between 1 and 3)::int as answer2
    from magnitude
    group by rn
)

select sum(answer2)
from checks