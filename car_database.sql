-- ==========================================
-- 汽车图片 & 产品信息数据库设计 (MySQL)
-- ==========================================

-- 1. 汽车图片表
CREATE TABLE car_images (
    id          BIGINT PRIMARY KEY AUTO_INCREMENT,
    image_url   VARCHAR(500) NOT NULL UNIQUE COMMENT '图片访问链接（通过此URL可直接拿到图片）',
    image_path  VARCHAR(500) NOT NULL COMMENT '图片存储路径（本地或OSS）',
    file_name   VARCHAR(255) NOT NULL COMMENT '文件名',
    file_size   INT          DEFAULT 0 COMMENT '文件大小（字节）',
    mime_type   VARCHAR(50)  DEFAULT 'image/jpeg' COMMENT 'MIME类型',
    width       INT          DEFAULT 0 COMMENT '图片宽度',
    height      INT          DEFAULT 0 COMMENT '图片高度',
    created_at  DATETIME     DEFAULT CURRENT_TIMESTAMP COMMENT '上传时间',
    updated_at  DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_created_at (created_at)
) COMMENT = '汽车图片存储表';


-- 2. 汽车产品信息表
CREATE TABLE car_products (
    id             BIGINT PRIMARY KEY AUTO_INCREMENT,
    product_name   VARCHAR(200) NOT NULL COMMENT '汽车产品名称',
    brand          VARCHAR(100) DEFAULT '' COMMENT '品牌',
    price          DECIMAL(10,2) DEFAULT 0.00 COMMENT '价格',
    product_json   JSON         NOT NULL COMMENT '产品完整信息JSON（包含图片链接列表等）',
    cover_image_id BIGINT       DEFAULT NULL COMMENT '封面图片ID',
    status         TINYINT      DEFAULT 1 COMMENT '状态：1上架 0下架',
    created_at     DATETIME     DEFAULT CURRENT_TIMESTAMP,
    updated_at     DATETIME     DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,

    INDEX idx_brand (brand),
    INDEX idx_status (status),

    FOREIGN KEY (cover_image_id) REFERENCES car_images(id) ON DELETE SET NULL
) COMMENT = '汽车产品信息表';


-- ==========================================
-- 示例数据
-- ==========================================

-- 插入图片记录
INSERT INTO car_images (image_url, image_path, file_name, file_size, mime_type, width, height)
VALUES
    ('https://cdn.example.com/cars/bmw-x5-front.jpg',    '/data/images/bmw-x5-front.jpg',    'bmw-x5-front.jpg',    524288,  'image/jpeg', 1920, 1080),
    ('https://cdn.example.com/cars/bmw-x5-side.jpg',     '/data/images/bmw-x5-side.jpg',     'bmw-x5-side.jpg',     489321,  'image/jpeg', 1920, 1080),
    ('https://cdn.example.com/cars/tesla-model3-front.jpg', '/data/images/tesla-model3-front.jpg', 'tesla-model3-front.jpg', 612000, 'image/jpeg', 1920, 1080);

-- 插入产品信息（JSON中包含图片链接）
INSERT INTO car_products (product_name, brand, price, product_json, cover_image_id)
VALUES
    ('BMW X5', '宝马', 699900.00, JSON_OBJECT(
        'images', JSON_ARRAY(
            'https://cdn.example.com/cars/bmw-x5-front.jpg',
            'https://cdn.example.com/cars/bmw-x5-side.jpg'
        ),
        'specs', JSON_OBJECT(
            'engine', '3.0T 直列六缸',
            'horsepower', 340,
            'transmission', '8速手自一体'
        )
    ), 1),

    ('Tesla Model 3', '特斯拉', 259900.00, JSON_OBJECT(
        'images', JSON_ARRAY(
            'https://cdn.example.com/cars/tesla-model3-front.jpg'
        ),
        'specs', JSON_OBJECT(
            'engine', '纯电动',
            'horsepower', 264,
            'transmission', '单速变速箱'
        )
    ), 3);


-- ==========================================
-- 常用查询示例
-- ==========================================

-- 1. 通过产品ID获取所有图片链接（直接从JSON取）
SELECT id, product_name,
       JSON_EXTRACT(product_json, '$.images') AS image_urls
FROM car_products
WHERE id = 1;

-- 2. 通过图片链接直接访问图片（查图片详情）
SELECT image_url, image_path, width, height
FROM car_images
WHERE image_url = 'https://cdn.example.com/cars/bmw-x5-front.jpg';

-- 3. 关联查询：产品 + 图片详细信息
SELECT p.product_name, i.image_url, i.file_size, i.width, i.height
FROM car_products p
JOIN car_images i ON JSON_CONTAINS(p.product_json, JSON_QUOTE(i.image_url), '$.images');

-- 4. 通过封面图ID获取封面图片
SELECT p.product_name, i.image_url
FROM car_products p
JOIN car_images i ON p.cover_image_id = i.id;
