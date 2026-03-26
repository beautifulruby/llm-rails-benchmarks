# Create demo users
alice = User.find_or_create_by!(email: "alice@example.com") do |u|
  u.name = "Alice Johnson"
end

bob = User.find_or_create_by!(email: "bob@example.com") do |u|
  u.name = "Bob Smith"
end

charlie = User.find_or_create_by!(email: "charlie@example.com") do |u|
  u.name = "Charlie Brown"
end

# Create demo posts
post1 = Post.find_or_create_by!(title: "Welcome to the Blog") do |p|
  p.user = alice
  p.body = <<~BODY
    Welcome to our new blog platform! This is a demonstration of the commenting system.

    Feel free to explore and leave comments on any of the posts. You can even reply to other comments to create threaded discussions.

    We hope you enjoy the experience!
  BODY
end

post2 = Post.find_or_create_by!(title: "Understanding Rails Architecture") do |p|
  p.user = bob
  p.body = <<~BODY
    Rails follows the Model-View-Controller (MVC) pattern, which separates concerns into three main components.

    The Model handles data and business logic. The View presents information to the user. The Controller processes requests and coordinates between models and views.

    This separation makes code more maintainable and testable. Each component has a clear responsibility.
  BODY
end

post3 = Post.find_or_create_by!(title: "The Power of Threaded Comments") do |p|
  p.user = charlie
  p.body = <<~BODY
    Threaded comments allow for more organized discussions. Instead of a flat list, replies are nested under their parent comments.

    This makes it easier to follow conversations and understand the context of each reply.

    Many popular platforms use threaded comments, including Reddit, Hacker News, and countless forums.
  BODY
end

# Create threaded comments on post1
comment1 = Comment.find_or_create_by!(post: post1, user: bob, parent: nil, body: "Great to see the blog up and running! Looking forward to more posts.")

comment2 = Comment.find_or_create_by!(post: post1, user: charlie, parent: comment1, body: "I agree! The threaded comments feature is really nice.")

Comment.find_or_create_by!(post: post1, user: alice, parent: comment2, body: "Thanks for the feedback! We worked hard on making the threading intuitive.")

Comment.find_or_create_by!(post: post1, user: bob, parent: nil, body: "Will there be email notifications for replies?")

# Create comments on post2
comment3 = Comment.find_or_create_by!(post: post2, user: alice, parent: nil, body: "Really clear explanation of MVC. This would help beginners understand Rails better.")

Comment.find_or_create_by!(post: post2, user: charlie, parent: comment3, body: "Definitely! I wish I had this when I was starting out.")

# Create comments on post3
comment4 = Comment.find_or_create_by!(post: post3, user: bob, parent: nil, body: "Threaded comments are a game changer for discussions.")

Comment.find_or_create_by!(post: post3, user: alice, parent: comment4, body: "Totally agree. Flat comment sections can get chaotic quickly.")

Comment.find_or_create_by!(post: post3, user: charlie, parent: comment4, body: "Reddit's approach to threading is my favorite implementation.")

puts "Seed data created: #{User.count} users, #{Post.count} posts, #{Comment.count} comments"
