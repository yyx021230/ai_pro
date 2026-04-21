-- ================================================================
--  汽车图片 & 产品信息数据库设计方案
--  数据库: MySQL 8.0+
--  设计者: Database Master
--  日期:   2026-04-14
-- ================================================================

-- ================================================================
--  一、数据库创建
-- ================================================================
CREATE DATABASE IF NOT EXISTS car_platform
  DEFAULT CHARACTER SET utf8mb4
  DEFAULT COLLATE utf8mb4_unicode_ci;

USE car_platform;


-- ================================================================
--  二、表结构设计
-- ================================================================

-- ┌──────────────────────────────────────────────────────────┐
-- │ 1. 汽车图片表 car_images                                │
-- │    职责：管理所有汽车图片元数据，提供统一的访问入口         │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE car_images (
    id              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键',
    image_url       VARCHAR(512)     NOT NULL              COMMENT '图片访问URL（公网/局域网可访问）',
    image_key       VARCHAR(256)     NOT NULL              COMMENT '图片存储唯一标识（用于存储层定位）',
    original_name   VARCHAR(256)     NOT NULL DEFAULT ''   COMMENT '原始文件名',
    file_ext        VARCHAR(16)      NOT NULL DEFAULT 'jpg' COMMENT '文件扩展名',
    file_size       BIGINT UNSIGNED  NOT NULL DEFAULT 0    COMMENT '文件大小（字节）',
    mime_type       VARCHAR(64)      NOT NULL DEFAULT 'image/jpeg' COMMENT 'MIME类型',
    width           INT UNSIGNED     NOT NULL DEFAULT 0    COMMENT '图片宽度（px）',
    height          INT UNSIGNED     NOT NULL DEFAULT 0    COMMENT '图片高度（px）',
    storage_type    TINYINT UNSIGNED NOT NULL DEFAULT 1    COMMENT '存储方式：1-本地 2-OSS 3-COS 4-S3',
    image_type      TINYINT UNSIGNED NOT NULL DEFAULT 1    COMMENT '图片类型：1-外观 2-内饰 3-细节 4-证件 5-其他',
    status          TINYINT UNSIGNED NOT NULL DEFAULT 1    COMMENT '状态：1-正常 0-已删除',
    md5_hash        CHAR(32)         NOT NULL DEFAULT ''   COMMENT '文件MD5（用于去重）',
    created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME         NULL                  COMMENT '软删除时间',

    PRIMARY KEY (id),
    UNIQUE INDEX uk_image_url (image_url),
    INDEX idx_image_key (image_key),
    INDEX idx_md5_hash (md5_hash),
    INDEX idx_storage_type (storage_type),
    INDEX idx_status_created (status, created_at)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='汽车图片表';


-- ┌──────────────────────────────────────────────────────────┐
-- │ 2. 汽车产品信息表 car_products                          │
-- │    职责：存储汽车产品的完整信息，JSON 包含结构化业务数据   │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE car_products (
    id              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键',
    product_code    VARCHAR(64)      NOT NULL              COMMENT '产品编码（业务唯一标识）',
    product_name    VARCHAR(200)     NOT NULL              COMMENT '产品名称',
    brand           VARCHAR(100)     NOT NULL DEFAULT ''   COMMENT '品牌名称',
    series          VARCHAR(100)     NOT NULL DEFAULT ''   COMMENT '车系',
    model_year      VARCHAR(16)      NOT NULL DEFAULT ''   COMMENT '年款',
    price           DECIMAL(12,2)    NOT NULL DEFAULT 0.00 COMMENT '指导价（元）',
    status          TINYINT UNSIGNED NOT NULL DEFAULT 1    COMMENT '状态：1-上架 0-下架 2-草稿',
    sort_order      INT              NOT NULL DEFAULT 0    COMMENT '排序权重',
    created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',
    updated_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '更新时间',
    deleted_at      DATETIME         NULL                  COMMENT '软删除时间',

    -- 产品详细信息（JSON格式）
    detail_json     JSON             NOT NULL              COMMENT '产品详情JSON',

    PRIMARY KEY (id),
    UNIQUE INDEX uk_product_code (product_code),
    INDEX idx_brand (brand),
    INDEX idx_status (status),
    INDEX idx_created (created_at),
    INDEX idx_price (price)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='汽车产品信息表';


-- ┌──────────────────────────────────────────────────────────┐
-- │ 3. 产品-图片关联表 car_product_images                   │
-- │    职责：解耦产品与图片的多对多关系，支持图片复用         │
-- └──────────────────────────────────────────────────────────┘
CREATE TABLE car_product_images (
    id              BIGINT UNSIGNED  NOT NULL AUTO_INCREMENT COMMENT '主键',
    product_id      BIGINT UNSIGNED  NOT NULL              COMMENT '产品ID',
    image_id        BIGINT UNSIGNED  NOT NULL              COMMENT '图片ID',
    image_role      VARCHAR(32)      NOT NULL DEFAULT ''   COMMENT '图片角色：cover-封面 gallery-轮播 detail-详情 certificate-证书',
    sort_order      INT              NOT NULL DEFAULT 0    COMMENT '排序',
    is_primary      TINYINT UNSIGNED NOT NULL DEFAULT 0    COMMENT '是否主图：1-是 0-否',
    created_at      DATETIME         NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '创建时间',

    PRIMARY KEY (id),
    UNIQUE INDEX uk_product_image (product_id, image_id),
    INDEX idx_product_id (product_id),
    INDEX idx_image_id (image_id),
    INDEX idx_image_role (image_role)

) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_unicode_ci
  COMMENT='产品-图片关联表';


-- ================================================================
--  三、detail_json 字段结构说明
-- ================================================================
/*
car_products.detail_json 的结构约定：

{
  "basic": {                          // 基础信息
    "engine": "3.0T 直列六缸",
    "horsepower": 340,
    "transmission": "8速手自一体",
    "fuel_type": "汽油",
    "drive_type": "四驱"
  },
  "dimensions": {                     // 尺寸
    "length": 4930,
    "width": 2004,
    "height": 1767,
    "wheelbase": 2975,
    "unit": "mm"
  },
  "specifications": {                 // 配置参数
    "air_conditioning": "自动空调",
    "sunroof": "全景天窗",
    "navigation": true,
    "driving_assist": ["自适应巡航", "车道保持", "自动刹车"]
  },
  "tags": ["豪华SUV", "四驱", "大空间"],  // 标签
  "description": "...",              // 文字描述
  "videos": []                       // 视频链接
}

注意：
- 图片链接不放在 detail_json 中，通过 car_product_images 关联表管理
- 这样可以复用图片、方便统计、支持图片级权限控制
- 如果图片属于某个具体规格项，可在 JSON 内部引用 image_id
*/


-- ================================================================
--  四、视图层：简化常用查询
-- ================================================================

-- 视图：产品完整信息（含图片列表）
CREATE OR REPLACE VIEW v_car_product_full AS
SELECT
    p.id                AS product_id,
    p.product_code,
    p.product_name,
    p.brand,
    p.series,
    p.model_year,
    p.price,
    p.status,
    p.detail_json,
    JSON_ARRAYAGG(
        JSON_OBJECT(
            'image_id',     i.id,
            'image_url',    i.image_url,
            'image_key',    i.image_key,
            'image_role',   cpi.image_role,
            'is_primary',   cpi.is_primary,
            'sort_order',   cpi.sort_order,
            'width',        i.width,
            'height',       i.height
        )
    )               AS images,
    p.created_at,
    p.updated_at
FROM car_products p
LEFT JOIN car_product_images cpi ON cpi.product_id = p.id AND cpi.image_id IS NOT NULL
LEFT JOIN car_images i           ON i.id = cpi.image_id AND i.status = 1 AND i.deleted_at IS NULL
WHERE p.status != 0 AND p.deleted_at IS NULL
GROUP BY p.id;


-- ================================================================
--  五、示例数据
-- ================================================================

-- 5.1 插入图片
INSERT INTO car_images (image_url, image_key, original_name, file_ext, file_size, mime_type, width, height, storage_type, image_type, md5_hash)
VALUES
    ('http://192.168.1.100:8080/images/bmw-x5-front.jpg',    'img_20260414_001', 'BMW_X5_正面.jpg',    'jpg', 524288,  'image/jpeg', 1920, 1080, 1, 1, 'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4'),
    ('http://192.168.1.100:8080/images/bmw-x5-side.jpg',     'img_20260414_002', 'BMW_X5_侧面.jpg',    'jpg', 489321,  'image/jpeg', 1920, 1080, 1, 1, 'b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5'),
    ('http://192.168.1.100:8080/images/bmw-x5-interior.jpg', 'img_20260414_003', 'BMW_X5_内饰.jpg',    'jpg', 412000,  'image/jpeg', 1920, 1080, 1, 2, 'c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6'),
    ('http://192.168.1.100:8080/images/tesla-m3-front.jpg',  'img_20260414_004', 'Tesla_M3_正面.jpg',  'jpg', 612000,  'image/jpeg', 1920, 1080, 1, 1, 'd4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1'),
    ('http://192.168.1.100:8080/images/tesla-m3-interior.jpg','img_20260414_005', 'Tesla_M3_内饰.jpg',  'jpg', 385000,  'image/jpeg', 1920, 1080, 1, 2, 'e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2');

-- 5.2 插入产品
INSERT INTO car_products (product_code, product_name, brand, series, model_year, price, status, detail_json)
VALUES
    ('BMW-X5-2026-001', 'BMW X5 xDrive40Li', '宝马', 'X5', '2026款', 729900.00, 1, JSON_OBJECT(
        'basic', JSON_OBJECT(
            'engine', '3.0T 直列六缸',
            'horsepower', 381,
            'transmission', '8速手自一体',
            'fuel_type', '汽油',
            'drive_type', '四驱'
        ),
        'dimensions', JSON_OBJECT(
            'length', 5060, 'width', 2004, 'height', 1779, 'wheelbase', 3105, 'unit', 'mm'
        ),
        'specifications', JSON_OBJECT(
            'air_conditioning', '四区自动空调',
            'sunroof', '全景玻璃天窗',
            'navigation', true,
            'driving_assist', JSON_ARRAY('自适应巡航', '车道保持', '自动刹车', '泊车辅助')
        ),
        'tags', JSON_ARRAY('豪华SUV', '四驱', '大空间', '进口'),
        'description', 'BMW X5 豪华SAV，融合动感设计与卓越驾控'
    )),

    ('TESLA-M3-2026-001', 'Tesla Model 3 后轮驱动版', '特斯拉', 'Model 3', '2026款', 239900.00, 1, JSON_OBJECT(
        'basic', JSON_OBJECT(
            'engine', '纯电动 后置电机',
            'horsepower', 264,
            'transmission', '单速固定齿比',
            'fuel_type', '纯电动',
            'drive_type', '后驱'
        ),
        'dimensions', JSON_OBJECT(
            'length', 4720, 'width', 1848, 'height', 1442, 'wheelbase', 2875, 'unit', 'mm'
        ),
        'specifications', JSON_OBJECT(
            'air_conditioning', '热泵空调',
            'sunroof', '全景玻璃车顶',
            'navigation', true,
            'driving_assist', JSON_ARRAY('Autopilot', '自动辅助导航驾驶', '自动泊车')
        ),
        'tags', JSON_ARRAY('纯电动', '智能驾驶', '轿车'),
        'description', 'Tesla Model 3 全新升级，续航与智能的双重进化'
    ));

-- 5.3 建立关联
INSERT INTO car_product_images (product_id, image_id, image_role, sort_order, is_primary)
VALUES
    -- BMW X5 的图片
    (1, 1, 'cover',   1, 1),   -- 封面主图
    (1, 2, 'gallery', 2, 0),   -- 轮播图
    (1, 3, 'gallery', 3, 0),   -- 轮播图（内饰）
    -- Tesla Model 3 的图片
    (2, 4, 'cover',   1, 1),
    (2, 5, 'gallery', 2, 0);


-- ================================================================
--  六、常用查询语句
-- ================================================================

-- Q1. 获取某个产品的完整信息（含所有图片）
SELECT * FROM v_car_product_full WHERE product_code = 'BMW-X5-2026-001';

-- Q2. 获取产品列表（含封面图URL）
SELECT
    p.product_code,
    p.product_name,
    p.brand,
    p.price,
    i.image_url AS cover_url
FROM car_products p
LEFT JOIN car_product_images cpi ON cpi.product_id = p.id AND cpi.is_primary = 1
LEFT JOIN car_images i           ON i.id = cpi.image_id AND i.status = 1
WHERE p.status = 1 AND p.deleted_at IS NULL
ORDER BY p.sort_order, p.created_at DESC;

-- Q3. 通过图片URL反查属于哪些产品
SELECT p.product_code, p.product_name, cpi.image_role
FROM car_images i
JOIN car_product_images cpi ON cpi.image_id = i.id
JOIN car_products p          ON p.id = cpi.product_id
WHERE i.image_url = 'http://192.168.1.100:8080/images/bmw-x5-front.jpg';

-- Q4. 查找重复图片（通过MD5）
SELECT md5_hash, COUNT(*) AS cnt, GROUP_CONCAT(id) AS image_ids
FROM car_images
WHERE status = 1
GROUP BY md5_hash
HAVING cnt > 1;

-- Q5. JSON 条件查询：查找所有带"四驱"的车
SELECT product_code, product_name
FROM car_products
WHERE JSON_EXTRACT(detail_json, '$.basic.drive_type') = '四驱'
  AND status = 1;

-- Q6. JSON 条件查询：查找包含"自动泊车"辅助驾驶功能的车
SELECT product_code, product_name
FROM car_products
WHERE JSON_CONTAINS(detail_json->'$.specifications.driving_assist', '"自动泊车"')
  AND status = 1;


-- ================================================================
--  七、架构说明
-- ================================================================
/*

  ┌─────────────────────────────────────────────────────────────────┐
  │                        应用层                                    │
  │   POST /api/products          → 创建产品                        │
  │   GET  /api/products          → 产品列表（含封面图）              │
  │   GET  /api/products/{code}   → 产品详情（含所有图片）            │
  │   GET  /api/images/{id}       → 图片详情                        │
  └─────────────────────────────────────────────────────────────────┘
                               │
  ┌─────────────────────────────────────────────────────────────────┐
  │                        数据库层                                  │
  │                                                                 │
  │  car_products ◄─────── car_product_images ──────► car_images   │
  │   (1)   ←─── N : N ───→    (N)                                  │
  │                                                                 │
  │  product detail_json 存储结构化业务数据                          │
  │  图片链接通过关联表管理，实现多对多、可复用                        │
  └─────────────────────────────────────────────────────────────────┘
                               │
  ┌─────────────────────────────────────────────────────────────────┐
  │                        图片服务层                                │
  │                                                                 │
  │  方案A（本地）: Python -m http.server / Nginx                   │
  │  方案B（云端）: 阿里云OSS / 腾讯云COS / AWS S3                   │
  │                                                                 │
  │  image_url = http://{host}:{port}/images/{image_key}.{ext}      │
  │  任何电脑浏览器打开 image_url 即可查看图片                       │
  └─────────────────────────────────────────────────────────────────┘

*/
