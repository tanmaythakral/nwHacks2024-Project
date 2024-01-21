import openai
openai.api_key = "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"

num_objects = 5
#
# response = openai.chat.completions.create( model="gpt-3.5-turbo", messages=[ {"role": "system", "content": "You are
# an image-idea generating system, which generates ideas for that are to be drawn by people. Images are realistic or
# semi-realistic, and should be drawable."}, {"role": "user", "content": "give an idea for an image, the image should
# have " + str(num_objects) + " distinct objects."}, ] )
#
# output = response.choices[0].message.content

# prompt = "Positive: images are pixel-art, objects within the image are not repeated - there are distinct objects in
# the image that are stitched together in one scene. Images are 2-D and flat. Image is minimalistic with simple
# backgrounds; There is only one frame in the image and only one scene" \ "Negative: images have repeated objects,
# Images are not 2-D, image has more than one frame, objects in the image are at differing depths; there are multiple
# frames in the image, images are unrealistic" + output

prompt = 'Create a 2D, completely flat pixel art image in portrait mode of a [specific scene, e.g., beach, garden, ' \
         'cityscape, desert, hills, bedroom], ensuring there is no depth perception and the background is simple. The ' \
         'image should include ' \
         'five distinct objects: [object 1], [object 2], [object 3], [object 4], and [object 5]. The background ' \
         'should be extremely minimal, featuring only flat shapes of [relevant background elements, e.g., ' \
         'sand and ocean, grass and sky, buildings and sky], with no shading or complex elements to suggest depth. ' \
         'The style should be clear, uncluttered, and simplistic, emphasizing the flatness and straightforwardness of '\
         'the scene.'

result = openai.images.generate(
  model="dall-e-3",
  prompt= prompt,
  size="1024x1792",
  quality="standard",
  n=1,
)

# print(output)
print(result)
