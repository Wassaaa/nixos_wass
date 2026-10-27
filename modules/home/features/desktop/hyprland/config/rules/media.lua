hl.window_rule({
  name = "picture-in-picture",
  match = { title = "Picture(-| )in(-| )[Pp]icture" },
  float = true, pin = true, move = "72% 7%", keep_aspect_ratio = true,
})
