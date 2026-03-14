from typing import List

import redis


class RedisMerger:
    def __init__(self):
        """
        初始化 Redis 合并器

        Args:
            redis_client: Redis 连接客户端
            config: 配置字典
        """
        self.redis = redis.Redis(
            host="192.168.0.5",
            port=6379,
            db=0,
            password="123456",
            decode_responses=True,  # 自动解码为字符串
        )

        # 配置参数
        self.config = {
            "domain": "p8_ax",
            "database": "api",
            "dest_id": 1,  # 目标区服id
            "merge_ids": [2],  # 被合并区服id
            "test": False,  # True: 测试模式
            "del_merge": False,  # True: 删除已合并的键
            "max_title": 35,  # 配置最大的身份等级
        }

        # 排行榜合并方式
        self.LB_AGGREGATE = {
            "SUM": "SUM",  # 相加
            "MIN": "MIN",  # 取最小值
            "MAX": "MAX",  # 取最大值
        }

        # 计数器合并方式
        self.COUNTER_AGGREGATE = {
            "SUM": 1,  # 相加
            "MIN": 2,  # 取最小值
            "MAX": 3,  # 取最大值
        }

        # 操作日志
        self.result = []

    def log(self, message: str):
        """记录操作日志"""
        self.result.append(message)

    def _scan_keys(self, scan_key: str):
        """
        使用 SCAN 命令模糊查询键
        """
        total_keys = []
        cursor = "0"
        while True:
            # 使用 SCAN 命令遍历键空间
            cursor, keys = self.redis.scan(cursor=cursor, match=scan_key)
            for key in keys:
                total_keys.append(key)
            if cursor == 0:  # 游标为 0 时结束遍历
                break
        return total_keys

    def _merge_lb(self, dest_key: str, merge_keys: List[str], lb_aggregate: str):
        """
        合并排行榜数据

        Args:
            dest_key: 目标键名
            merge_keys: 需要合并的键名列表
            lb_aggregate: 合并方式 (SUM/MIN/MAX)
        """
        # 过滤出存在的键
        real_merge_keys = []

        if self.redis.exists(dest_key):
            self.log(f"merge: {dest_key}")
            real_merge_keys.append(dest_key)

        for merge_key in merge_keys:
            if self.redis.exists(merge_key):
                self.log(f"merge: {merge_key}")
                real_merge_keys.append(merge_key)

        if not real_merge_keys:
            self.log(f"no keys to merge: {dest_key}")
            return

        # 执行合并操作
        if not self.config.get("test", False):
            self.redis.zunionstore(dest_key, real_merge_keys)
            self.log(f"to: {dest_key}")

        # 删除已合并的键
        if not self.config.get("test", False) and self.config.get("del_merge", False):
            for merge_key in real_merge_keys:
                if merge_key != dest_key:
                    self.redis.delete(merge_key)
                    self.log(f"deleted: {merge_key}")

    def _merge_counter(
        self, dest_key: str, merge_keys: List[str], counter_aggregate: int
    ):
        """
        合并计数器数据

        Args:
            dest_key: 目标键名
            merge_keys: 需要合并的键名列表
            counter_aggregate: 合并方式 (1:SUM, 2:MIN, 3:MAX)
        """
        new_value = int(self.redis.get(dest_key) or 0)
        self.log(f"{dest_key} = {new_value}")

        for merge_key in merge_keys:
            merge_value = int(self.redis.get(merge_key) or 0)

            if counter_aggregate == self.COUNTER_AGGREGATE["SUM"]:
                new_value += merge_value
            elif counter_aggregate == self.COUNTER_AGGREGATE["MIN"]:
                new_value = min(new_value, merge_value)
            elif counter_aggregate == self.COUNTER_AGGREGATE["MAX"]:
                new_value = max(new_value, merge_value)

            self.log(f"{merge_key} = {merge_value} new_value = {new_value}")

            # 删除合并键
            if (
                not self.config.get("test", False)
                and self.config.get("del_merge", False)
                and merge_key != dest_key
            ):
                self.redis.delete(merge_key)
                self.log(f"deleted {merge_key}")

        # 设置新值
        if not self.config.get("test", False):
            self.redis.set(dest_key, new_value)
            self.log(f"set {dest_key} = {new_value}")

    def merge_promotion_path_lb(self):
        """合并晋升之路排行榜"""
        self.log(
            "--------------------func_merge_promotion_path_lb start--------------------"
        )

        max_title = self.config.get("max_title", 30)

        for i in range(1, max_title + 1):
            self.log(f"title_id: {i}")

            # 目标键
            dest_key = f"{self.config['database']}:lb:{self.config['domain']}:{self.config['domain']}_1_{self.config['dest_id']}_player_1007_{i}"

            # 需要合并的键
            merge_keys = []
            for merge_id in self.config["merge_ids"]:
                merge_key = f"{self.config['database']}:lb:{self.config['domain']}:{self.config['domain']}_1_{merge_id}_player_1007_{i}"
                merge_keys.append(merge_key)

            # 执行合并
            self._merge_lb(dest_key, merge_keys, self.LB_AGGREGATE["MAX"])

        self.log(
            "--------------------func_merge_promotion_path_lb end--------------------"
        )

    def merge_promotion_path_counter(self):
        """合并晋升之路计数器"""
        self.log(
            "--------------------func_merge_promotion_path_counter start--------------------"
        )

        dest_key = f"{self.config['database']}:counter:{self.config['domain']}:{self.config['domain']}_counter_1_{self.config['dest_id']}_6"

        merge_keys = []
        for merge_id in self.config["merge_ids"]:
            merge_key = f"{self.config['database']}:counter:{self.config['domain']}:{self.config['domain']}_counter_1_{merge_id}_6"
            merge_keys.append(merge_key)

        self._merge_counter(dest_key, merge_keys, self.COUNTER_AGGREGATE["MAX"])
        self.log(
            "--------------------func_merge_promotion_path_counter end--------------------"
        )

    def merge_tower_secret_counter(self):
        """合并秘境探索计数器"""
        self.log(
            "--------------------func_merge_tower_secret_counter start--------------------"
        )

        dest_scan_key = f"{self.config['database']}:counter:{self.config['domain']}:{self.config['domain']}_counter_1_{self.config['dest_id']}_1_*"
        dest_keys = self._scan_keys(dest_scan_key)

        dest_goals = set()
        for dest_key in dest_keys:
            suffix = dest_key.rsplit("_", 1)[-1]
            if suffix not in dest_goals:
                dest_goals.add(suffix)

        for merge_id in self.config["merge_ids"]:
            merge_scan_key = f"{self.config['database']}:counter:{self.config['domain']}:{self.config['domain']}_counter_1_{merge_id}_1_*"
            merge_keys = self._scan_keys(merge_scan_key)
            for merge_key in merge_keys:
                suffix = merge_key.rsplit("_", 1)[-1]
                if suffix not in dest_goals:
                    dest_goals.add(suffix)

        self.log(f"merge dest_goals: {dest_goals}")

        for suffix in dest_goals:
            dest_key = f"{self.config['database']}:counter:{self.config['domain']}:{self.config['domain']}_counter_1_{self.config['dest_id']}_1_{suffix}"

            merge_keys = []
            for merge_id in self.config["merge_ids"]:
                merge_key = f"{self.config['database']}:counter:{self.config['domain']}:{self.config['domain']}_counter_1_{merge_id}_1_{suffix}"
                merge_keys.append(merge_key)

            self._merge_counter(dest_key, merge_keys, self.COUNTER_AGGREGATE["SUM"])
        self.log(
            "--------------------func_merge_tower_secret_counter end--------------------"
        )

    def execute(self):
        """执行所有合并操作"""
        self.merge_promotion_path_lb()
        self.merge_promotion_path_counter()
        self.merge_tower_secret_counter()
        return self.result


# 使用示例
def main():
    # 创建合并器并执行
    merger = RedisMerger()
    result = merger.execute()

    # 打印结果
    for line in result:
        print(line)

    return result


if __name__ == "__main__":
    main()
