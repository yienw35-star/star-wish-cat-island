# Character portrait assets

The game code now references one independent portrait file per character:

- xingya.webp — 星芽
- yanwei.webp — 焰尾
- yueshuang.webp — 月霜
- senlu.webp — 森露
- xingli.webp — 星璃
- yunmeng.webp — 雲夢
- tangguo.webp — 糖果
- mogu.webp — 蘑菇
- youyou.webp — 悠悠
- doudou.webp — 豆豆

Target art specification for each file:
- 1024 × 1536 pixels or higher, portrait 2:3 composition
- Full-body character, centered, entire ears/hair/accessories/shoes inside frame
- Consistent high-quality anime fantasy gacha illustration style
- Distinct character palette and element motifs
- No text, logos, card frame, UI, watermark, or extra characters
- Prefer transparent WebP/PNG; otherwise use a clean, simple matching background

The current game keeps the old sprite sheet as a temporary visual fallback for the nine characters that have sprite positions. Doudou keeps its existing icon until the separate illustration is added. Do not delete the fallback until all ten files have been uploaded and checked in the live game.
