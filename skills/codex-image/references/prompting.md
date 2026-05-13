# Prompting best practices

These prompting principles are shared across the generate and edit flows in this skill.

This file is about prompt structure and iteration. API controls such as `quality`, `background`, `output_format`, `output_compression`, `mask`, and `input_fidelity` are execution settings, not prompt content.

## Structure

- Use a consistent order: scene/backdrop -> subject -> key details -> constraints -> output intent.
- For complex requests, use short labeled lines instead of one long paragraph.
- Include intended use when it affects polish or composition, such as wallpaper, poster, hero image, sticker, infographic, or UI mockup.
- For `gpt-image-2`, treat the prompt as a visual brief. Start with the output type and canvas, then allocate layout and hierarchy before adding visual surface detail.
- Put canvas, aspect ratio, and layout before the subject when composition matters, for example `Landscape 16:9 cinematic city scene`, `Vertical 9:16 product poster`, or `3x2 storyboard grid`.

## Specificity policy

- If the user prompt is already detailed, normalize it into a cleaner spec.
- If the prompt is generic, add only the detail that materially improves the result.
- Treat the examples in `sample-prompts.md` as complete recipes, not the default amount of augmentation to add every time.
- Translate vague taste words into concrete visual controls. For example, `premium` should become restraint, negative space, material quality, careful typography, and controlled lighting; `cinematic` should become camera angle, depth, lighting contrast, and scene tension.

## Allowed augmentation

- composition and framing cues
- intended-use or polish-level hints
- practical layout guidance
- reasonable scene concreteness that supports the stated request

Do not add:

- extra characters, props, or objects not implied by the request
- brand palettes, slogans, or story beats not implied by the request
- arbitrary left/right placement without surrounding layout context

## Constraints and invariants

- State what must not change.
- For edits, say `change only X; keep Y unchanged`.
- Repeat invariants on every iteration to reduce drift.
- For edit calls, name each input image's role and preserve identity, layout, text, position, geometry, and brand elements when they matter.
- Use short avoid-lines only for likely failure modes such as garbled text, fake logos, cluttered collage, wrong aspect ratio, or style drift.

## Text in images

- Put literal text in quotes and require verbatim rendering when text matters.
- Specify typography and placement when needed.
- For image-only requests, explicitly say `no text`.
- Keep required in-image copy short and layout-bound. For dense text, list title, subtitle, module labels, legend labels, axis labels, prices, or buttons as separate quoted strings.
- Use high quality for final assets with readable text, UI, diagrams, multilingual copy, or small labels.
- For dense body copy, long URLs, model names, rates, invoices, configuration instructions, or multilingual posters, split the workflow: ask the model for a no-text background or illustration, then render the exact copy locally with PIL, canvas, HTML/CSS screenshot, or another deterministic text renderer. This avoids hallucinated characters and broken URLs.

## Complex prompt patterns

Use these patterns when a simple scene prompt is not enough.

### JSON or config-style prompts

Use JSON-like structure for product renders, food photography, UI mockups, information graphics, brand systems, and scenes with many interacting constraints.

```text
{
  "type": "<asset type>",
  "canvas": "<aspect ratio or exact size>",
  "subject": "<primary subject>",
  "layout": "<regions, hierarchy, camera, grid, or panel system>",
  "style": "<medium and production context>",
  "lighting": "<light source, direction, contrast>",
  "materials": ["<surface>", "<texture>", "<finish>"],
  "text": ["<exact readable string>"],
  "constraints": ["<must keep>", "<must avoid>"]
}
```

The keys should describe visual subsystems, not code internals. Keep values concrete.

### UI and app mockups

Write UI prompts like product specs:

- name the device or canvas
- define navigation, cards, charts, rows, controls, and empty states
- provide exact labels and plausible data
- require crisp typography, spacing, alignment, and production-quality mockup polish
- avoid generic `modern clean app` wording without concrete interface structure

### Infographics and diagrams

Use diagram grammar:

- artifact type, audience, and layout zones
- modules, arrows, nodes, callouts, legends, axes, labels, and units
- visual encoding such as color meanings, line styles, or ribbon thickness
- short readable labels instead of paragraphs
- publication-grade hierarchy, margins, and no garbled text

### Commercial posters and product visuals

Specify promotional hierarchy:

- hero subject or product first
- headline, subtitle, price/date/CTA only when provided or clearly requested
- material, lighting, palette, background, and camera as separate controls
- distance readability and negative space
- no fake logos or sponsor strips unless the user provides them

### Multi-panel boards

For storyboards, character sheets, grids, small multiples, and reference boards:

- state exact panel count and grid shape
- give each panel a role, beat, view, or action
- repeat shared identity, costume, palette, lighting, and style constraints
- require consistent axes/labels for data panels

### Photorealism

Name capture context instead of only saying `realistic`:

- camera or device feel, such as `RAW iPhone photo`, `50mm lens`, `handheld`, or `shot from the crowd`
- time, place, light direction, and ordinary imperfections
- real materials, surface wear, shadows, reflections, and environmental clutter when appropriate

Pick one dominant capture frame. Do not stack conflicting camera specs.

## Quality and iteration

- Use `quality=high` for final text-heavy images, UI, diagrams, posters, and dense layouts.
- Use lower quality for broad exploration, then rerun finalists with stricter prompt wording and higher quality.
- Start with a clean base prompt, then change one variable at a time.
- Re-state must-keep constraints on every follow-up.

## External references consulted

These are reference sources for prompt-craft guidance, not runtime dependencies:

- OpenAI GPT Image 2 model docs: `https://developers.openai.com/api/docs/models/gpt-image-2`
- OpenAI image generation guide: `https://platform.openai.com/docs/guides/image-generation`
- OpenAI Cookbook image prompting guide: `https://developers.openai.com/cookbook/examples/multimodal/image-gen-models-prompting-guide`
- YouMind-OpenLab prompt gallery: `https://github.com/YouMind-OpenLab/awesome-gpt-image-2`
- freestylefly industrial template library: `https://github.com/freestylefly/awesome-gpt-image-2`
- wuyoscar GPT Image 2 skill craft reference: `https://github.com/wuyoscar/gpt_image_2_skill`
- zhouwei713 GPT-Image-2 prompting skill: `https://github.com/zhouwei713/gpt-image-2-prompting-skill`

## Direct-size guidance

- Prefer direct final sizes whenever the user provides an exact delivery size.
- When the user provides only a ratio like `16:9`, `9:16`, or `6:16`, let the skill convert it to the largest valid direct-request size.
- When the user provides both a ratio and a tier such as `9:16 1k`, `16:9 2k`, or `4k 9:16`, use the CLI ratio-tier syntax such as `--size '9:16@1k'` rather than passing the plain ratio.
- Keep the prompt explicit about the final canvas dimensions. The CLI adds this automatically for resolved direct sizes; do not contradict it with text such as "4K" when requesting `1k`.
- For explicit non-standard sizes, pass the user-requested `WIDTHxHEIGHT` to the API and describe that same final size in the prompt.
- If the generated result comes back with a materially different aspect ratio, do not silently distort it. Ask whether to retry through the model with stricter canvas wording or apply a chosen post-processing strategy.
- Do not plan on cropping, padding, or local upscaling after generation.

## Input images

- If actual image files are provided for the model to see, use `edit`, not `generate`, even when creating a new poster or mockup.
- Do not assume every provided image is a base image to modify; some inputs may be role references, product references, style references, or masks.
- For multi-image edits, label each input role clearly, for example `Input image 1 role: person reference` and `Input image 2 role: product reference`.
- Restate what must stay fixed from each input image.
- In Codex-thread attachment flows, `[Image #N]` only addresses the most recent attachment-bearing user turn. After a follow-up that adds one new image, use `[Image #1]` for that new image and switch older images to `[Turn -1 Image #N]`, `[Thread Image #N]`, or explicit `--image-set`.
- Prefer direct invocation of `python3 "$CODEX_IMAGE"` or the full bundled script path. Do not rely on a `codex-image` shell alias being present.

## Iteration

- Start with a clean base prompt.
- Change one thing at a time on follow-up iterations.
- Re-state the must-keep constraints every time.
- In follow-up turns that add new attachment images, restate the role of every carried-forward image explicitly so the command shape stays stable.

## Suggested shared schema

```text
Use case: <taxonomy slug>
Asset type: <where the image will be used>
Primary request: <main request>
Input images: <Image 1: role> (optional)
Scene/backdrop: <setting>
Subject: <main subject>
Style/medium: <photo/illustration/3D/etc>
Composition/framing: <wide/close/top-down; placement>
Lighting/mood: <lighting + mood>
Color palette: <palette notes>
Materials/textures: <surface details>
Text (verbatim): "<exact text>"
Constraints: <must keep/must avoid>
Avoid: <negative constraints>
```
