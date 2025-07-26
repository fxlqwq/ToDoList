#!/bin/bash

# 一键查看lib目录下所有Dart文件的代码行数和字符数统计
# 作者：AI助手
# 日期：$(date '+%Y-%m-%d')

echo "=========================================="
echo "        Flutter项目代码行数统计"
echo "=========================================="
echo ""

# 检查lib目录是否存在
if [ ! -d "lib" ]; then
    echo "错误：未找到lib目录！"
    echo "请确保在Flutter项目根目录下运行此脚本。"
    exit 1
fi

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 统计各种类型的行数和字符数
total_lines=0
total_code_lines=0
total_comment_lines=0
total_blank_lines=0
total_files=0
total_chars=0
total_code_chars=0

echo -e "${BLUE}📊 详细统计信息：${NC}"
echo ""

# 按目录分类统计
declare -A dir_stats
declare -A dir_files
declare -A dir_chars

# 遍历所有dart文件
while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
        total_files=$((total_files + 1))
        
        # 获取文件的目录
        dir=$(dirname "$file")
        
        # 统计各种行数
        lines=$(wc -l < "$file")
        code_lines=$(grep -v '^\s*$' "$file" | grep -v '^\s*//' | grep -v '^\s*/\*' | grep -v '^\s*\*' | wc -l)
        comment_lines=$(grep -E '^\s*(//|/\*|\*)' "$file" | wc -l)
        blank_lines=$(grep -E '^\s*$' "$file" | wc -l)
        
        # 统计字符数
        chars=$(wc -c < "$file")
        code_chars=$(grep -v '^\s*$' "$file" | grep -v '^\s*//' | grep -v '^\s*/\*' | grep -v '^\s*\*' | wc -c)
        
        # 累加总计
        total_lines=$((total_lines + lines))
        total_code_lines=$((total_code_lines + code_lines))
        total_comment_lines=$((total_comment_lines + comment_lines))
        total_blank_lines=$((total_blank_lines + blank_lines))
        total_chars=$((total_chars + chars))
        total_code_chars=$((total_code_chars + code_chars))
        
        # 按目录累加
        if [[ -z "${dir_stats[$dir]}" ]]; then
            dir_stats[$dir]=0
            dir_files[$dir]=0
            dir_chars[$dir]=0
        fi
        dir_stats[$dir]=$((${dir_stats[$dir]} + lines))
        dir_files[$dir]=$((${dir_files[$dir]} + 1))
        dir_chars[$dir]=$((${dir_chars[$dir]} + chars))
        
        echo -e "${CYAN}📄 $(basename "$file")${NC} (${file#lib/}): ${YELLOW}$lines${NC} 行, ${BLUE}$chars${NC} 字符"
    fi
done < <(find lib -name "*.dart" -type f -print0 | sort -z)

echo ""
echo "=========================================="
echo -e "${GREEN}📂 按目录统计：${NC}"
echo "=========================================="

for dir in "${!dir_stats[@]}"; do
    dir_name=${dir#lib/}
    if [[ "$dir_name" == "lib" ]]; then
        dir_name="根目录"
    fi
    echo -e "${PURPLE}📁 $dir_name${NC}: ${YELLOW}${dir_stats[$dir]}${NC} 行, ${BLUE}${dir_chars[$dir]}${NC} 字符 (${dir_files[$dir]} 个文件)"
done

echo ""
echo "=========================================="
echo -e "${GREEN}🎯 总体统计：${NC}"
echo "=========================================="
echo -e "${BLUE}📂 总文件数：${NC} ${YELLOW}$total_files${NC} 个Dart文件"
echo -e "${BLUE}📝 总行数：${NC} ${YELLOW}$total_lines${NC} 行"
echo -e "${BLUE}💻 代码行数：${NC} ${GREEN}$total_code_lines${NC} 行"
echo -e "${BLUE}💬 注释行数：${NC} ${CYAN}$total_comment_lines${NC} 行"
echo -e "${BLUE}⬜ 空行数：${NC} ${PURPLE}$total_blank_lines${NC} 行"
echo -e "${BLUE}📊 总字符数：${NC} ${YELLOW}$total_chars${NC} 字符"
echo -e "${BLUE}💡 代码字符数：${NC} ${GREEN}$total_code_chars${NC} 字符"

# 计算代码密度
if [ $total_lines -gt 0 ]; then
    code_ratio=$(echo "scale=1; $total_code_lines * 100 / $total_lines" | bc -l 2>/dev/null || echo "N/A")
    comment_ratio=$(echo "scale=1; $total_comment_lines * 100 / $total_lines" | bc -l 2>/dev/null || echo "N/A")
    
    echo ""
    echo -e "${BLUE}📈 代码质量指标：${NC}"
    echo -e "${BLUE}💡 代码密度：${NC} ${GREEN}$code_ratio%${NC}"
    echo -e "${BLUE}📋 注释率：${NC} ${CYAN}$comment_ratio%${NC}"
fi

echo ""
echo "=========================================="
echo -e "${GREEN}🏆 文件大小排行（前10名）：${NC}"
echo "=========================================="

# 获取文件大小排行
find lib -name "*.dart" -type f -exec wc -l {} + | sort -nr | head -10 | while read lines file; do
    if [[ "$file" != "总用量" && "$file" != "total" ]]; then
        filename=$(basename "$file")
        filepath=${file#lib/}
        echo -e "${YELLOW}$lines${NC} 行 - ${CYAN}$filename${NC} (${filepath})"
    fi
done

echo ""
echo "=========================================="
echo -e "${GREEN}✨ 统计完成！${NC}"
echo "=========================================="
echo -e "生成时间：${BLUE}$(date '+%Y-%m-%d %H:%M:%S')${NC}"

# 生成Code_info.md文件
echo ""
echo -e "${YELLOW}📝 正在生成 Code_info.md 文件...${NC}"

cat > Code_info.md << EOF
# Flutter项目代码统计报告

## 项目基本信息
- **项目名称**: todo_list_app  
- **统计时间**: $(date '+%Y-%m-%d %H:%M:%S')
- **统计范围**: lib/ 目录下的所有 .dart 文件

## 📊 总体统计

| 指标 | 数量 |
|------|------|
| 📂 Dart文件总数 | $total_files 个 |
| 📝 代码总行数 | $total_lines 行 |
| 💻 有效代码行数 | $total_code_lines 行 |
| 💬 注释行数 | $total_comment_lines 行 |
| ⬜ 空行数 | $total_blank_lines 行 |
| 📊 总字符数 | $total_chars 字符 |
| 💡 代码字符数 | $total_code_chars 字符 |

## 📈 代码质量指标

EOF

if [ $total_lines -gt 0 ]; then
    code_ratio=$(echo "scale=1; $total_code_lines * 100 / $total_lines" | bc -l 2>/dev/null || echo "N/A")
    comment_ratio=$(echo "scale=1; $total_comment_lines * 100 / $total_lines" | bc -l 2>/dev/null || echo "N/A")
    char_per_line=$(echo "scale=1; $total_chars / $total_lines" | bc -l 2>/dev/null || echo "N/A")
    
    cat >> Code_info.md << EOF
| 指标 | 比例/平均值 |
|------|------------|
| 💡 代码密度 | $code_ratio% |
| 📋 注释率 | $comment_ratio% |
| 📏 平均每行字符数 | $char_per_line 字符/行 |

EOF
else
    cat >> Code_info.md << EOF
| 指标 | 比例/平均值 |
|------|------------|
| 💡 代码密度 | N/A |
| 📋 注释率 | N/A |
| 📏 平均每行字符数 | N/A |

EOF
fi

cat >> Code_info.md << EOF
## 📂 目录结构统计

| 目录 | 行数 | 字符数 | 文件数 |
|------|------|--------|--------|
EOF

for dir in "${!dir_stats[@]}"; do
    dir_name=${dir#lib/}
    if [[ "$dir_name" == "lib" ]]; then
        dir_name="根目录"
    fi
    echo "| 📁 $dir_name | ${dir_stats[$dir]} 行 | ${dir_chars[$dir]} 字符 | ${dir_files[$dir]} 个文件 |" >> Code_info.md
done

cat >> Code_info.md << EOF

## 🏆 文件大小排行榜（前10名）

| 排名 | 文件名 | 路径 | 行数 |
|------|--------|------|------|
EOF

# 生成文件大小排行
rank=1
find lib -name "*.dart" -type f -exec wc -l {} + | sort -nr | head -10 | while read lines file; do
    if [[ "$file" != "总用量" && "$file" != "total" ]]; then
        filename=$(basename "$file")
        filepath=${file#lib/}
        echo "| $rank | $filename | $filepath | $lines 行 |" >> Code_info.md
        rank=$((rank + 1))
    fi
done

cat >> Code_info.md << EOF

## 📋 详细文件列表

| 文件名 | 路径 | 行数 | 字符数 |
|--------|------|------|--------|
EOF

# 生成详细文件列表
while IFS= read -r -d '' file; do
    if [ -f "$file" ]; then
        lines=$(wc -l < "$file")
        chars=$(wc -c < "$file")
        filename=$(basename "$file")
        filepath=${file#lib/}
        echo "| $filename | $filepath | $lines 行 | $chars 字符 |" >> Code_info.md
    fi
done < <(find lib -name "*.dart" -type f -print0 | sort -z)

cat >> Code_info.md << EOF

---

**报告生成工具**: count_lib_lines.sh  
**生成时间**: $(date '+%Y-%m-%d %H:%M:%S')  
**项目版本**: Flutter项目代码统计工具 v2.0
EOF

echo -e "${GREEN}✅ Code_info.md 文件生成完成！${NC}"
echo ""
