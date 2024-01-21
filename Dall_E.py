import openai
openai.api_key = "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"

num_objects = 5
#
response = openai.chat.completions.create(
  model="gpt-3.5-turbo",
  messages=[ {"role": "system", "content": "You are an image-idea generating system, which generates ideas for that are to be drawn by people. image should be in portrait mode of a [specific scene, e.g., rooftop, garden, beach, mountains, midday sky] at [time of day, e.g., dusk, daytime, night], and should be drawable."},
             {"role": "user", "content": "give an idea for such an image, the image should have " + str(num_objects) + " distinct drawable objects. Make sure the ideas are diverse and exciting"},
  ])
output = response.choices[0].message.content
print(output)
# prompt = "Positive: images are pixel-art, objects within the image are not repeated - there are distinct objects in
# the image that are stitched together in one scene. Images are 2-D and flat. Image is minimalistic with simple
# backgrounds; There is only one frame in the image and only one scene" \ "Negative: images have repeated objects,
# Images are not 2-D, image has more than one frame, objects in the image are at differing depths; there are multiple
# frames in the image, images are unrealistic" + output

prompt = "Create a 2D, high-resolution pixel art image in portrait mode of a [specific scene, e.g., rooftop, garden, beach, mountains, midday sky] at [time of day, e.g., dusk, daytime, night], ensuring there is no depth perception and the background is simple. The image should include five distinct and easily identifiable objects: [object 1], [object 2], [object 3], [object 4], and [object 5]. The background should be minimal, featuring only flat shapes of [relevant background elements, e.g., rooftops and sky, grass and sky, buildings and sky], with no shading or complex elements to suggest depth. The style should be clear, not cluttered, with distinct pixels, ensuring each object is recognizable and not overly pixelated. Make the objects in the photos extremely big. The image should be simple and easy to draw. Take inspiration from - " + output

result = openai.images.generate(
  model="dall-e-3",
  prompt=prompt,
  size="1024x1792",
  quality="standard",
  n=1,
)


print(result)
