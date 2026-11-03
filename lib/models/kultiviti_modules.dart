class KultivitiModule {
  final String id;
  final String title;
  final String level;
  final String prompt;

  KultivitiModule({
    required this.id,
    required this.title,
    required this.level,
    required this.prompt,
  });
}

final List<KultivitiModule> kultivitiModules = [
  KultivitiModule(
    id: "1",
    level: "Iniciante",
    title: "PresentaciÃ³n y Saludos",
    prompt: "El usuario estÃ¡ aprendiendo saludos y presentaciones. Practica cÃ³mo saludar, presentarse, preguntar nombres, nacionalidades y origen.",
  ),
  KultivitiModule(
    id: "2",
    level: "Iniciante",
    title: "Alquilar un Piso y Por la Ciudad",
    prompt: "Simula situaciones de alquiler de apartamentos, pedir direcciones en la ciudad y describir ubicaciones.",
  ),
  KultivitiModule(
    id: "3",
    level: "Iniciante",
    title: "En el Restaurant e Ir de Compras",
    prompt: "Simula estar en un restaurante pidiendo comida o en una tienda comprando ropa. Practica vocabulario de comida y precios.",
  ),
  KultivitiModule(
    id: "4",
    level: "Iniciante",
    title: "HÃ¡blame de Ti e Invitaciones",
    prompt: "Habla sobre rutinas diarias, gustos y haz invitaciones para salir. Practica conectores sencillos.",
  ),
  KultivitiModule(
    id: "5",
    level: "Iniciante",
    title: "Pasado Cercano (Â¿QuÃ© Has Hecho? / Â¿QuÃ© Hiciste?)",
    prompt: "EnfÃ³cate en hacer preguntas sobre experiencias recientes y eventos pasados especÃ­ficos.",
  ),
  KultivitiModule(
    id: "6",
    level: "IntermediÃ¡rio",
    title: "Llevo Haciendo / Â¿QuÃ© HacÃ­a?",
    prompt: "Practica estructuras de duraciÃ³n ('llevo + gerundio') y el PretÃ©rito Imperfecto.",
  ),
  KultivitiModule(
    id: "7",
    level: "IntermediÃ¡rio",
    title: "Futuro y Condicional (Haremos / HarÃ­a)",
    prompt: "Conversa sobre proyectos futuros y situaciones hipotÃ©ticas o consejos.",
  ),
  KultivitiModule(
    id: "8",
    level: "IntermediÃ¡rio",
    title: "Instrucciones y Subjuntivo (Haga / Vaya)",
    prompt: "Simula situaciones donde das instrucciones y consejos amables usando Subjuntivo e Imperativo.",
  ),
  KultivitiModule(
    id: "9",
    level: "IntermediÃ¡rio",
    title: "Vida Social, Trabajo y PolÃ©mica",
    prompt: "Habla sobre el entorno laboral, estilo de vida y debates sencillos.",
  ),
  KultivitiModule(
    id: "10",
    level: "AvanÃ§ado",
    title: "TecnologÃ­a, Medio Ambiente y Actualidad",
    prompt: "Entabla debates profundos sobre tecnologÃ­a, impacto ambiental y sociedad moderna.",
  ),
  KultivitiModule(
    id: "11",
    level: "AvanÃ§ado",
    title: "Cultura, Cine y Expresiones IdiomÃ¡ticas",
    prompt: "Habla sobre cine, historias y modismos o expresiones idiomÃ¡ticas en espaÃ±ol.",
  ),
];
