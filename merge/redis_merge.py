import redis

# 连接 Redis
redis_client = redis.Redis(
    host="192.168.250.250", port=6379, password="123456", decode_responses=True
)

# 定义变量
domain = "p8"
database = "gameapi"
dest_id = 1  # 目标区服ID
merge_id = 2  # 被合并区服ID

# 构建计数器键前缀
counter = f"{database}:counter:{domain}:{domain}_counter_1_"
scan_merge_key = f"{counter}{merge_id}_1_*"


def scan_keys(scan_key):
    """使用SCAN命令模糊查询键"""
    results = []
    cursor = "0"

    while True:
        # 使用SCAN命令遍历键空间
        cursor, keys = redis_client.scan(cursor=cursor, match=scan_key)

        for key in keys:
            # 获取键对应的值
            value = redis_client.get(key)
            if value is not None:
                value = int(value)  # 假设值是整数
            results.append({"key": key, "value": value})

        if cursor == 0:  # 游标为0时结束遍历
            break

    return results


def merge_counters():
    """合并计数器"""
    # 查询被合并区服的键
    items = scan_keys(scan_merge_key)
    results = []

    for item in items:
        # 构建目标区服的键
        dest_key = str(item["key"]).replace(
            f"{counter}{merge_id}", f"{counter}{dest_id}"
        )

        # 获取目标区服的值
        dest_key = dest_key.encode()
        dest_value = redis_client.get(dest_key)
        dest_value = int(dest_value) if dest_value is not None else 0

        # 计算新值
        new_value = item["value"] + dest_value

        if new_value > 0:
            # 更新目标区服的值
            redis_client.set(dest_key, str(new_value))

        # 记录结果
        results.append(
            {
                "merge_key": item["key"],
                "merge_value": item["value"],
                "dest_key": dest_key,
                "dest_value": dest_value,
                "new_value": new_value,
            }
        )

    return results


# 执行合并操作
results = merge_counters()

for result in results:
    print(result)
