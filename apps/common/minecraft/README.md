

```
helm template --name minecraft-bedrock \
  --set minecraftServer.eula=true,minecraftServer.Difficulty=hard \
  itzg/minecraft > minecraft.yaml
```