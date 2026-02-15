Use ig_clone;
Select * from users;
#         Objective Questions 
# Question 1

# To check for duplicates 

Select id,image_url,user_id,created_dat,count(*) as cnt
from photos
group by 1,2,3,4
having count(*) > 1;

# To check for null values
Select id,image_url,user_id,created_dat as cnt
from photos
where id is null or image_url is null or user_id is null or created_dat is null;

#Question 2

SELECT 
    u.username,
    COALESCE(p.total_posts, 0)     AS total_posts,
    COALESCE(l.total_likes, 0)     AS total_likes,
    COALESCE(c.total_comments, 0)  AS total_comments,
    COALESCE(f.total_followers, 0) AS total_followers
FROM users u

LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
) p ON u.id = p.user_id

LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
) l ON u.id = l.user_id

LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
) c ON u.id = c.user_id

LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
) f ON u.id = f.user_id

ORDER BY total_likes DESC, total_comments DESC
LIMIT 10;

#Question 3

select
round(count(pt.tag_id) * 1.0 / Count(distinct p.id), 2) as avg_tags_per_post
from photos p
LEFT JOIN
photo_tags pt ON 
p.id = pt.photo_id;

#Question 4

select
username,
total_posts,
total_likes_received,
total_comments_received,
like_engagement_rate,
comment_engagement_rate,
(like_engagement_rate + comment_engagement_rate) as total_engagement_rate,
RANK() OVER (ORDER BY (like_engagement_rate + comment_engagement_rate) DESC) as
engagement_rank
from(
select u.username,
COALESCE(p.total_posts,0) as total_posts,
COALESCE(l.total_likes,0) as total_likes_received,
COALESCE(c.total_comments,0) as total_comments_received,
round(COALESCE(l.total_likes,0)*1.0/GREATEST(p.total_posts,1),2) as like_engagement_rate,
round(coalesce(c.total_comments,0)*1.0/GREATEST(p.total_posts,1),2) as comment_engagement_rate
from users u
LEFT JOIN(
select user_id,count(*) as total_posts
from photos
group by user_id)
p on u.id = p.user_id

LEFT JOIN(
select p.user_id,count(*) as total_likes
from photos p
join likes l 
on l.photo_id = p.id
group by p.user_id) l on u.id = l.user_id

LEFT JOIN(
select p.user_id,count(*) as total_comments
from photos p
join comments c on c.photo_id = p.id
group by p.user_id) c on u.id = c.user_id
where COALESCE(p.total_posts,0)>0) ranked
order by engagement_rank
limit 10;

#Question 5 

SELECT 
  u.username,
  u.id as user_id,
  COALESCE(followers.total_followers, 0) AS total_followers,
  COALESCE(followings.total_followings, 0) AS total_followings
FROM users u
LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
) followers ON u.id = followers.user_id
LEFT JOIN (
    SELECT follower_id AS user_id, COUNT(*) AS total_followings
    FROM follows
    GROUP BY follower_id
) followings ON u.id = followings.user_id
ORDER BY 
total_followings DESC,
total_followers DESC,
u.username asc
LIMIT 10;

#Question 6

SELECT 
  u.username,
  COALESCE(p.total_posts, 0) AS total_posts,
  COALESCE(l.total_likes, 0) AS total_likes,
  COALESCE(c.total_comments, 0) AS total_comments,
  ROUND(COALESCE(l.total_likes * 1.0, 0) / NULLIF(p.total_posts, 0), 2) AS avg_likes_per_post,
  ROUND(COALESCE(c.total_comments * 1.0, 0) / NULLIF(p.total_posts, 0), 2) AS avg_comments_per_post
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
) p ON u.id = p.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
) c ON u.id = c.user_id
WHERE p.total_posts IS NOT NULL
ORDER BY avg_likes_per_post DESC, avg_comments_per_post DESC
limit 10;

#Question 7

SELECT distinct u.username
FROM users u
LEFT JOIN likes l ON u.id = l.user_id
WHERE l.user_id IS NULL;

#Question 8

with tags as (
SELECT 
    u.id AS user_id,
    u.username,
    t.tag_name,
    COUNT(*) AS tag_usage_count
FROM users u
JOIN photos p ON u.id = p.user_id
JOIN photo_tags pt ON p.id = pt.photo_id
JOIN tags t ON pt.tag_id = t.id
GROUP BY u.id, u.username, t.tag_name
ORDER BY u.id, tag_usage_count DESC
),
ranking as(
select
user_id,
username,
tag_name,
tag_usage_count,
row_number() over(partition by user_id order by tag_usage_count desc) as rnk
from tags
)
select 
*
from ranking
where rnk =1;

#Question 9

SELECT 
    u.id AS user_id,
    u.username,
    COUNT(DISTINCT p.id) AS total_photos_posted,
    COUNT(DISTINCT l.photo_id) AS total_likes_given,
    COUNT(DISTINCT c.id) AS total_comments_made,
    (
        SELECT COUNT(*) 
        FROM likes l2
        JOIN photos p2 ON l2.photo_id = p2.id
        WHERE p2.user_id = u.id
    ) AS total_likes_received,
    (
        SELECT COUNT(*) 
        FROM comments c2
        JOIN photos p2 ON c2.photo_id = p2.id
        WHERE p2.user_id = u.id
    ) AS total_comments_received
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
LEFT JOIN likes l ON u.id = l.user_id
LEFT JOIN comments c ON u.id = c.user_id
GROUP BY u.id, u.username
HAVING COUNT(DISTINCT p.id) > 0
ORDER BY total_photos_posted DESC;

#Question 10

SELECT 
  u.username,
  COALESCE(p.total_posts, 0) AS total_posts,
  COALESCE(l.total_likes, 0) AS total_likes,
  COALESCE(c.total_comments, 0) AS total_comments,
  COALESCE(t.total_tags, 0) AS total_photo_tags
FROM users u
LEFT JOIN (
    SELECT distinct user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
) p ON u.id = p.user_id
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
) c ON u.id = c.user_id
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(*) AS total_tags
    FROM photos p
    JOIN photo_tags pt ON p.id = pt.photo_id
    GROUP BY p.user_id
) t ON u.id = t.user_id
WHERE p.total_posts IS NOT NULL
ORDER BY total_likes DESC, total_comments DESC
Limit 10;

#Question 11

SELECT 
  u.username,
  COALESCE(l.total_likes, 0) AS total_likes,
  COALESCE(c.total_comments, 0) AS total_comments,
  (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) AS total_engagement,
  RANK() OVER (ORDER BY (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) DESC) AS engagement_rank
FROM users u
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(distinct l.photo_id) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    WHERE l.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    GROUP BY p.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT distinct p.user_id, COUNT(distinct c.id) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    WHERE c.created_at >= DATE_SUB(CURDATE(), INTERVAL 1 MONTH)
    GROUP BY p.user_id
) c ON u.id = c.user_id
ORDER BY total_engagement DESC
limit 10;

#Question 12

WITH tag_likes_cte AS (
  SELECT 
    t.tag_name,
    COUNT(l.user_id) * 1.0 / COUNT(DISTINCT pt.photo_id) AS avg_likes_per_post
  FROM photo_tags pt
  JOIN tags t ON pt.tag_id = t.id
  JOIN likes l ON pt.photo_id = l.photo_id
  GROUP BY t.tag_name
)
SELECT *
FROM tag_likes_cte
ORDER BY avg_likes_per_post DESC
LIMIT 10;

#Question 13

SELECT 
  f1.follower_id AS user_id,
  f1.followee_id AS followed_back_user,
  f1.created_at AS followed_at,
  f2.created_at AS was_followed_at
FROM follows f1
JOIN follows f2 
  ON f1.follower_id = f2.followee_id 
  AND f1.followee_id = f2.follower_id
WHERE 
  f1.follower_id != f1.followee_id -- avoid self-follow
  AND f1.created_at >= f2.created_at -- followed AFTER being followed and followed at the same time
ORDER BY f1.created_at
limit 10;

#				Subjective Questions

#Question 1

SELECT 
  u.username,
  COALESCE(p.total_posts, 0) AS total_posts,
  COALESCE(l.total_likes, 0) AS total_likes,
  ROUND(COALESCE(l.total_likes, 0) / NULLIF(p.total_posts, 0), 2) AS avg_likes_per_post,
  COALESCE(c.total_comments, 0) AS total_comments,
  ROUND(COALESCE(c.total_comments, 0) / NULLIF(p.total_posts, 0), 2) AS avg_comments_per_post,
  COALESCE(f.total_followers, 0) AS total_followers
FROM users u
LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
) p ON u.id = p.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_likes
    FROM photos p
    JOIN likes l ON p.id = l.photo_id
    GROUP BY p.user_id
) l ON u.id = l.user_id
LEFT JOIN (
    SELECT p.user_id, COUNT(*) AS total_comments
    FROM photos p
    JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
) c ON u.id = c.user_id
LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
) f ON u.id = f.user_id
ORDER BY avg_likes_per_post DESC, avg_comments_per_post DESC
LIMIT 10;

#Question 2

SELECT *
FROM users u
LEFT JOIN photos p ON u.id = p.user_id
WHERE p.id IS NULL
order by u.id
limit 10;

#Question 3

WITH hashtag_engagement AS (
  SELECT 
    ht.tag_name,
    COUNT(DISTINCT l.photo_id) AS total_likes,        -- count actual likes
    COUNT(DISTINCT c.id) AS total_comments,     -- count actual comments
    COUNT(DISTINCT p.id) AS total_photos
  FROM tags ht
  join photos p on ht.id=p.user_id
  JOIN photo_tags pt ON ht.id = pt.tag_id
  LEFT JOIN likes l ON pt.photo_id = l.photo_id
  LEFT JOIN comments c ON pt.photo_id = c.photo_id
  GROUP BY ht.tag_name
)
SELECT 
  tag_name,
  total_likes,
  total_comments,
  total_photos,
  ROUND(total_likes * 1.0 / NULLIF(total_photos, 0), 2) AS avg_likes_per_post,
  ROUND(total_comments * 1.0 / NULLIF(total_photos, 0), 2) AS avg_comments_per_post
FROM hashtag_engagement
ORDER BY avg_likes_per_post DESC, avg_comments_per_post DESC;

#Question 4

SELECT 
  HOUR(u.created_at) AS post_hour,
  COUNT(DISTINCT l.photo_id) AS likes,
  COUNT(DISTINCT c.id) AS comments
FROM photos p
join users u on p.id=u.id
LEFT JOIN likes l ON p.id = l.photo_id
LEFT JOIN comments c ON p.id = c.photo_id
GROUP BY post_hour
ORDER BY post_hour;

#Question 5

SELECT 
  username,
  follower_count,
  total_posts,
  total_likes_received,
  total_comments_received,
  engagement_rate_percent
FROM (
    SELECT 
      u.username,
	  COALESCE(follower_data.follower_count, 0) AS follower_count,
      COALESCE(p.total_posts, 0) AS total_posts,
      COALESCE(l.total_likes, 0) AS total_likes_received,
      COALESCE(c.total_comments, 0) AS total_comments_received,
      ROUND(
        (COALESCE(l.total_likes, 0) + COALESCE(c.total_comments, 0)) * 100.0 
        / NULLIF(COALESCE(follower_data.follower_count, 0) * COALESCE(p.total_posts, 0), 0), 
        2
    ) AS engagement_rate_percent
    FROM users u
    LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS follower_count
    FROM follows
    GROUP BY followee_id
    ) AS follower_data ON u.id = follower_data.user_id
    LEFT JOIN (
        SELECT user_id, COUNT(*) AS total_posts
        FROM photos
        GROUP BY user_id
    ) p ON u.id = p.user_id
    LEFT JOIN (
        SELECT p.user_id, COUNT(*) AS total_likes
        FROM photos p
        JOIN likes l ON l.photo_id = p.id
        GROUP BY p.user_id
    ) l ON u.id = l.user_id
    LEFT JOIN (
        SELECT p.user_id, COUNT(*) AS total_comments
        FROM photos p
        JOIN comments c ON c.photo_id = p.id
        GROUP BY p.user_id
    ) c ON u.id = c.user_id
    WHERE COALESCE(p.total_posts, 0) > 0
) ranked
ORDER BY engagement_rate_percent DESC, follower_count DESC
LIMIT 10;

#Question 6

SELECT segment, COUNT(*) AS total_users
FROM (
  SELECT 
    u.id,
    CASE
      WHEN COALESCE(p.total_posts, 0) >= 10 AND COALESCE(e.total_engagement, 0) >= 100 THEN 'Highly Engaged'
      WHEN COALESCE(p.total_posts, 0) >= 15 THEN 'Creators'
      WHEN COALESCE(f.total_followers, 0) >= 100 THEN 'Influencers'
      WHEN COALESCE(p.total_posts, 0) = 0 AND COALESCE(e.total_engagement, 0) = 0 THEN 'Inactive Users'
      WHEN COALESCE(c.total_comments, 0) >= 20 THEN 'Commenters'
      ELSE 'Other'
    END AS segment
  FROM users u
  LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_posts
    FROM photos
    GROUP BY user_id
  ) p ON u.id = p.user_id
  LEFT JOIN (
    SELECT p.user_id, COUNT(l.photo_id) + COUNT(c.id) AS total_engagement
    FROM photos p
    LEFT JOIN likes l ON p.id = l.photo_id
    LEFT JOIN comments c ON p.id = c.photo_id
    GROUP BY p.user_id
  ) e ON u.id = e.user_id
  LEFT JOIN (
    SELECT followee_id AS user_id, COUNT(*) AS total_followers
    FROM follows
    GROUP BY followee_id
  ) f ON u.id = f.user_id
  LEFT JOIN (
    SELECT user_id, COUNT(*) AS total_comments
    FROM comments
    GROUP BY user_id
  ) c ON u.id = c.user_id
) categorized
GROUP BY segment
ORDER BY segment;



