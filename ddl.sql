CREATE TABLE recipes (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `author_id` int(10) unsigned NOT NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE users (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `account_name` varchar(16) NOT NULL,
    PRIMARY KEY (`id`)
);

CREATE TABLE iines (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `recipe_id` int(10) unsigned NOT NULL,
    `user_id` int(10) unsigned NOT NULL,
    PRIMARY KEY (`id`),
    FOREIGN KEY (`recipe_id`) REFERENCES recipes (`id`),
    FOREIGN KEY (`user_id`) REFERENCES users (`id`)
);
