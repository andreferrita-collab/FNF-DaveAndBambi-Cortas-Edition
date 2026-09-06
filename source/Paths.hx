package;

import flixel.graphics.frames.FlxAtlasFrames;
import flixel.graphics.FlxGraphic;
import flixel.FlxSprite;
import flixel.FlxG;

class Paths
{
    // Retorna um atlas de sparrow (Frames) esperado pelo FlxAtlasFrames.fromSparrow
    public static function getSparrowAtlas(id:String):FlxAtlasFrames
    {
        switch (id)
        {
            case "androidcontrols/hitbox":
                // Ajuste estes nomes se o seu AssetPaths gerou chaves diferentes
                return FlxAtlasFrames.fromSparrow(
                    "assets/androidcontrols/hitbox.png",
                    "assets/androidcontrols/hitbox.xml"
                );
            // Adicione outros casos aqui conforme necessário
            default:
                return null;
        }
    }

    // Retorna um caminho de imagem (string) para uso com loadGraphic se preferir esse fluxo
    public static function image(id:String):String
    {
        switch (id)
        {
            case "androidcontrols/hitbox":
                // caminho relativo esperado pelo loadGraphic. Ajuste se a sua pasta/nomes for diferente.
                return "assets/images/androidcontrols/hitbox.png";
            // Adicione outros casos conforme necessário
            default:
                return "";
        }
    }
}
