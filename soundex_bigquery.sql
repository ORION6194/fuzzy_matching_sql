CREATE OR REPLACE FUNCTION `bq_ds.fuzzy_match_soundex`(input STRING) AS ((
select
  rpad(string_agg(if(off = 0, upper(c), digit), "" order by off), 4, "0")
from (select
        c, digit, off
      from  (select
              c, digit, off,
              coalesce(digit = lag(digit) over (order by off), false) as is_same_as_prev_digit,
              coalesce((lag(c) over (order by off) in ('w', 'h')) and (digit = lag(digit, 2) over (order by off)), false) as is_same_as_2_digit_prev_separated_by_w_or_h
            from (select
                    c,
                    cast(case when c in ('a', 'e', 'i', 'o', 'u', 'y', 'h', 'w') then 0
                             when c in ('b', 'f', 'p', 'v') then 1
                             when c in ('c', 'g', 'j', 'k', 'q', 's', 'x', 'z') then 2
                             when c in ('d', 't') then 3
                             when c = 'l' then 4
                             when c in ('m', 'n') then 5
                             when c = 'r' then 6
                             else 7
                        end as string) as digit,
                   off
                from unnest(split(lower(input), '')) as c with offset off
                ) as digitised_string
            )
      where not is_same_as_prev_digit
      and not is_same_as_2_digit_prev_separated_by_w_or_h
      )
where digit not in ('0', '7') or off = 0
));
