// Some definitions presupposed by pandoc's typst output.
#let blockquote(body) = [
  #set text( size: 0.92em )
  #block(inset: (left: 1.5em, top: 0.2em, bottom: 0.2em))[#body]
]

#let horizontalrule = line(start: (25%,0%), end: (75%,0%))

#let endnote(num, contents) = [
  #stack(dir: ltr, spacing: 3pt, super[#num], contents)
]

#show terms: it => {
  it.children
    .map(child => [
      #strong[#child.term]
      #block(inset: (left: 1.5em, top: -0.4em))[#child.description]
      ])
    .join()
}

// Some quarto-specific definitions.

#show raw.where(block: true): set block(
    fill: luma(230),
    width: 100%,
    inset: 8pt,
    radius: 2pt
  )

#let block_with_new_content(old_block, new_content) = {
  let d = (:)
  let fields = old_block.fields()
  fields.remove("body")
  if fields.at("below", default: none) != none {
    // TODO: this is a hack because below is a "synthesized element"
    // according to the experts in the typst discord...
    fields.below = fields.below.abs
  }
  return block.with(..fields)(new_content)
}

#let empty(v) = {
  if type(v) == str {
    // two dollar signs here because we're technically inside
    // a Pandoc template :grimace:
    v.matches(regex("^\\s*$")).at(0, default: none) != none
  } else if type(v) == content {
    if v.at("text", default: none) != none {
      return empty(v.text)
    }
    for child in v.at("children", default: ()) {
      if not empty(child) {
        return false
      }
    }
    return true
  }

}

// Subfloats
// This is a technique that we adapted from https://github.com/tingerrr/subpar/
#let quartosubfloatcounter = counter("quartosubfloatcounter")

#let quarto_super(
  kind: str,
  caption: none,
  label: none,
  supplement: str,
  position: none,
  subrefnumbering: "1a",
  subcapnumbering: "(a)",
  body,
) = {
  context {
    let figcounter = counter(figure.where(kind: kind))
    let n-super = figcounter.get().first() + 1
    set figure.caption(position: position)
    [#figure(
      kind: kind,
      supplement: supplement,
      caption: caption,
      {
        show figure.where(kind: kind): set figure(numbering: _ => numbering(subrefnumbering, n-super, quartosubfloatcounter.get().first() + 1))
        show figure.where(kind: kind): set figure.caption(position: position)

        show figure: it => {
          let num = numbering(subcapnumbering, n-super, quartosubfloatcounter.get().first() + 1)
          show figure.caption: it => {
            num.slice(2) // I don't understand why the numbering contains output that it really shouldn't, but this fixes it shrug?
            [ ]
            it.body
          }

          quartosubfloatcounter.step()
          it
          counter(figure.where(kind: it.kind)).update(n => n - 1)
        }

        quartosubfloatcounter.update(0)
        body
      }
    )#label]
  }
}

// callout rendering
// this is a figure show rule because callouts are crossreferenceable
#show figure: it => {
  if type(it.kind) != str {
    return it
  }
  let kind_match = it.kind.matches(regex("^quarto-callout-(.*)")).at(0, default: none)
  if kind_match == none {
    return it
  }
  let kind = kind_match.captures.at(0, default: "other")
  kind = upper(kind.first()) + kind.slice(1)
  // now we pull apart the callout and reassemble it with the crossref name and counter

  // when we cleanup pandoc's emitted code to avoid spaces this will have to change
  let old_callout = it.body.children.at(1).body.children.at(1)
  let old_title_block = old_callout.body.children.at(0)
  let old_title = old_title_block.body.body.children.at(2)

  // TODO use custom separator if available
  let new_title = if empty(old_title) {
    [#kind #it.counter.display()]
  } else {
    [#kind #it.counter.display(): #old_title]
  }

  let new_title_block = block_with_new_content(
    old_title_block, 
    block_with_new_content(
      old_title_block.body, 
      old_title_block.body.body.children.at(0) +
      old_title_block.body.body.children.at(1) +
      new_title))

  block_with_new_content(old_callout,
    block(below: 0pt, new_title_block) +
    old_callout.body.children.at(1))
}

// 2023-10-09: #fa-icon("fa-info") is not working, so we'll eval "#fa-info()" instead
#let callout(body: [], title: "Callout", background_color: rgb("#dddddd"), icon: none, icon_color: black, body_background_color: white) = {
  block(
    breakable: false, 
    fill: background_color, 
    stroke: (paint: icon_color, thickness: 0.5pt, cap: "round"), 
    width: 100%, 
    radius: 2pt,
    block(
      inset: 1pt,
      width: 100%, 
      below: 0pt, 
      block(
        fill: background_color, 
        width: 100%, 
        inset: 8pt)[#text(icon_color, weight: 900)[#icon] #title]) +
      if(body != []){
        block(
          inset: 1pt, 
          width: 100%, 
          block(fill: body_background_color, width: 100%, inset: 8pt, body))
      }
    )
}



#let article(
  title: none,
  subtitle: none,
  authors: none,
  date: none,
  abstract: none,
  abstract-title: none,
  cols: 1,
  lang: "en",
  region: "US",
  font: "libertinus serif",
  fontsize: 11pt,
  title-size: 1.5em,
  subtitle-size: 1.25em,
  heading-family: "libertinus serif",
  heading-weight: "bold",
  heading-style: "normal",
  heading-color: black,
  heading-line-height: 0.65em,
  sectionnumbering: none,
  toc: false,
  toc_title: none,
  toc_depth: none,
  toc_indent: 1.5em,
  doc,
) = {
  set par(justify: true)
  set text(lang: lang,
           region: region,
           font: font,
           size: fontsize)
  set heading(numbering: sectionnumbering)
  if title != none {
    align(center)[#block(inset: 2em)[
      #set par(leading: heading-line-height)
      #if (heading-family != none or heading-weight != "bold" or heading-style != "normal"
           or heading-color != black) {
        set text(font: heading-family, weight: heading-weight, style: heading-style, fill: heading-color)
        text(size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(size: subtitle-size)[#subtitle]
        }
      } else {
        text(weight: "bold", size: title-size)[#title]
        if subtitle != none {
          parbreak()
          text(weight: "bold", size: subtitle-size)[#subtitle]
        }
      }
    ]]
  }

  if authors != none {
    let count = authors.len()
    let ncols = calc.min(count, 3)
    grid(
      columns: (1fr,) * ncols,
      row-gutter: 1.5em,
      ..authors.map(author =>
          align(center)[
            #author.name \
            #author.affiliation \
            #author.email
          ]
      )
    )
  }

  if date != none {
    align(center)[#block(inset: 1em)[
      #date
    ]]
  }

  if abstract != none {
    block(inset: 2em)[
    #text(weight: "semibold")[#abstract-title] #h(1em) #abstract
    ]
  }

  if toc {
    let title = if toc_title == none {
      auto
    } else {
      toc_title
    }
    block(above: 0em, below: 2em)[
    #outline(
      title: toc_title,
      depth: toc_depth,
      indent: toc_indent
    );
    ]
  }

  if cols == 1 {
    doc
  } else {
    columns(cols, doc)
  }
}

#set table(
  inset: 6pt,
  stroke: none
)

#set page(
  paper: "us-letter",
  margin: (x: 1.25in, y: 1.25in),
  numbering: "1",
)

#show: doc => article(
  authors: (
    ( name: [Colin Madland, Mark Halvorson, Scott Macklin],
      affiliation: [],
      email: [] ),
    ),
  date: [Sep 18, 2025],
  sectionnumbering: "1.1.a",
  toc: true,
  toc_title: [Table of contents],
  toc_depth: 3,
  cols: 2,
  doc,
)

= Learning in Community
<learning-in-community>
@tedTheresMoreLife2017

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Things To Do This Week
]
)
]
- #strong[Before you start: Follow] the instructions on the '#link("https://twuonline.github.io/ldrs663-q/obsidian.html")[Getting Started with Obsidian];' page in the course notes in Moodle.

- #strong[Read] #link("https://www-sciencedirect-com.twu.idm.oclc.org/science/article/pii/S1096751600000166")[Critical inquiry in a text-based environment: Computer conferencing in higher education] \

- #strong[Read] #link("http://www.irrodl.org/index.php/irrodl/article/view/149/230")[Getting the mix right again: An updated and theoretical rationale for interaction] \

- #strong[Read] #link("https://rdcu.be/cKSGf")[Interaction and the online distance classroom: Do instructional methods effect the quality of interaction?] \

- #strong[Write] your arguments for or against the #emph[Interaction Equivalency Theorem] in the Learning community. \

- #strong[Draft] your autoethnography proposal according to the instructions in the 'Assessment Tasks' section in Moodle.

- To get started thinking about autoethnography, please refer to this article available in the TWU Library. Chang, H. (2021). #emph[Individual and Collaborative Autoethnography for Social Science Research];. In T. E. Adams, S. H. Jones, & C. Ellis (Eds.), Handbook of Autoethnography (2nd ed., pp.~53--65). Routledge. DOI: 10.4324/9780429431760-6

- Please complete these tasks by #strike[Sunday, Jul 28] #strong[Sunday, Aug 3] before your regular bedtime.

#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
Overview
]
)
]
Welcome to Unit 1 of LDRS 463/663! In this unit, we will begin by considering the nature of learning communities through the lens of a model called the #emph[Community of Inquiry (CoI)] (#link("https://www.sciencedirect.com/science/article/pii/S1096751600000166?")[Garrison et al., 2000];; #link("http://www.aupress.ca/index.php/books/120229")[Vaughan et al., 2013];). The CoI model proposes that there are three overlapping components, or presences, to any learning environment; cognitive presence (constructing meaning), social presence (projecting a sense of yourself), and teaching presence (designing and facilitating the learning experience). The CoI model is grounded in a long history of social constructivism which is the idea that learning is fundamentally a social process (#link("https://en.wikisource.org/wiki/My_Pedagogic_Creed")[Dewey, 1897];; #link("https://twu.idm.oclc.org/login?url=http://search.ebscohost.com/login.aspx?direct=true&db=cat05965a&AN=alc.191437&site=eds-live")[Vygotsky, 1978];). We will also consider various modes of interaction in learning environments and how these two models have informed the model of teaching and learning in TWU online courses.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Topics
]
)
]
This unit is divided into the following topics:

+ Introduction to the Community of Inquiry Model \
+ Modes of Interaction \
+ Interaction Equivalency Theorem

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Unit Learning Outcomes
]
)
]
When you have completed this unit, you will be able to:

- Analyze the characteristics of the Community of Inquiry model.
- Evaluate different modes of interaction.
- Criticize the Interaction Equivalency Theorem.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Learning Activities
]
)
]
Here is a list of learning activities that will benefit you in completing this unit. You may find it useful for planning your work.

+ \*#link("https://twu.discourse.group/t/introductions-and-learning-stories")[Introductions and Learning Stories\* topic in the Learning Community.]
+ #link(<activity-exploring-the-community-of-inquiry>)[Exploring the Community of Inquiry:] Read #emph[Critical Inquiry in a Text-Based Environment: Computer Conferencing in Higher Education];.
+ #link(<activity-what-is-interaction>)[What Is Interaction?:] Watch #emph[You Keep Using That Word] and consider what interaction is.
+ #link(<activity-theoretical-rationale-for-interaction>)[Theoretical Rationale for Interaction:] Read #emph[Getting the Mix Right Again: An Updated and Theoretical Rationale for Interaction];.

#block[
Working through course activities will help you to meet the learning outcomes and successfully complete your assessments.

]
#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Assessment
]
)
]
Please see the Assessment section in Moodle for assignment details.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Resources
]
)
]
Here are the resources you will need to complete this unit:

- Garrison, D. R., Anderson, T., & Archer, W. (1999). #link("https://doi.org/10.1016/S1096-7516(00)00016-6")[#emph[Critical Inquiry in a Text-Based Environment: Computer Conferencing in Higher Education];];. The Internet and Higher Education, 2(2), 87--105.
- Anderson, T. (2023, October). #link("http://www.irrodl.org/index.php/irrodl/article/view/149/230")[#emph[Getting the Mix Right Again: An Updated and Theoretical Rationale for Interaction];];| The International Review of Research in Open and Distributed Learning.
- Kanuka, H. (2011). #link("https://rdcu.be/cKSGf")[#emph[Interaction and the Online Distance Classroom: Do Instructional Methods Effect the Quality of Interaction?];] 23(2--3).

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Optional Resource
]
)
]
- Vaughan, N., Cleveland-Innes, M., & Garrison, D. (2013). #link("http://www.aupress.ca/index.php/books/120229")[#emph[Teaching in blended learning environments: Creating and sustaining communities of inquiry.];] Athabasca: AU Press. (This book is available for free at AUPress.)

== Introduction to the Community of Inquiry Model
<sec-learning-stories>
Before you dive into the content of this unit in LDRS 463/663, take a moment to recall some particularly memorable learning experiences that you have had. They don't have to be particularly profound in terms of #emph[what] you learned, but profound because of the fact that you still remember #emph[that] you learned something and #emph[how] you learned it. Pick one or two of those experiences and share them in the \*#link("https://twu.discourse.group/t/introductions-and-learning-stories")[Introductions and Learning Stories\* topic in the Learning Community.] Make sure to tell us about the context of your experience. Who was there? What did you do to learn? Why do you remember it?

=== Social Constructivism
<social-constructivism>
There is a very good chance that your recollection of a memorable learning experience as part of the previous learning activity included a description of some sort of social interaction. This isn't always the case, but the idea that learning is a social process has a long history in education. Many theorists credit John Dewey for bringing this idea to the forefront of educators' minds. In his 1897 treatise #emph[My Pedagogic Creed] he writes:

#quote(block: true)[
I believe that the school is primarily a social institution. Education being a social process, the school is simply that form of community life in which all those agencies are concentrated that will be most effective in bringing the child to share in the inherited resources of the race, and to use his own powers for social ends. (p.~7)
]

The idea didn't originate with Dewey, though, as we know that in first-century Palestine there was a certain itinerant teacher whose lessons were profoundly impactful on a small group of young men and women who were called to live and learn in a deeply personal and social community.

Following Dewey, many others, such as Jean Piaget, Jerome Bruner, and Lev Vygotsky have written about what has now become known as the educational theory of #emph[social constructivism];, or, more concisely, constructivism @driscollPsychologyLearningInstruction2005. Driscoll describes constructivism as a theory that

#quote(block: true)[
rests on the assumption that knowledge is constructed by learners as they attempt to make sense of their experiences. Learners, therefore are not empty vessels waiting to be filled, but rather active organisms seeking meaning. (p.387)
]

This process of seeking meaning is an iterative process whereby the learner experiences some sort of cognitive dissonance, or a disconnect between what they previously knew and some new piece of evidence or experience that disconfirms that knowledge. The learner then seeks to resolve that dissonance by either incorporating the new experience into an older schema, or by disregarding one or the other. Most often, the resulting knowledge is constructed from portions of both the new and old idea.

=== Community of Inquiry
<community-of-inquiry>
This brings us to the idea of a 'Community of Inquiry' (CoI), which was first described by Garrison, Anderson, and Archer in their 2000 article "Critical Inquiry in a text-based environment". Garrison, et al.~theorize that there are three critical components, or "presences" that compose an interactive, online learning environment: Cognitive presence, social presence, and teaching presence. The intersection of these three presences is the heart of an educational experience.

#figure([
#box(image("assets/u2/CoI-Model.png", width: 4.16667in))
], caption: figure.caption(
position: bottom, 
[
Figure 1.1 Community of Inquiry Model (Garrison, et al., (2000)
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Cognitive Presence
]
)
]
Cognitive presence, possibly the most foundational element, is the \> extent to which the participants in any particular configuration of a community of inquiry are able to construct meaning through sustained communication (p.~89).

Recall that this cognitive process is at the heart of constructivist learning environments. It seems obvious (be careful when people say that) that this construction of meaning through communication is the entire point of higher education. Your task as a student is to change your own mind, and that is a very tall order as our beliefs about many things are remarkably resilient. The way we engage in this task will have a significant bearing on the outcomes of the task.

If we approach communication with too much confidence in our own views, we can shut out competing ideas to our own detriment, so it is important to bring a cautious intelligence, or, as I once heard a student describe it, epistemic humility. We all know that we are wrong about some things. The trouble is we don't know what we are wrong about and how we have misunderstood.

Cognitive presence in a text-based environment (like an online course) carries with it some affordances, but also some disadvantages. It is a relatively common experience for people to type something in a text message or an email, only to have their intentions grossly misunderstood because there are fewer para-linguistic cues in text compared to verbal face-to-face communication. Recent developments in incorporating emojis have started to change this, but emojis are generally considered to be too informal for 'serious scholarly work' or written professional communication. So, the relatively lean environment of text can lead to significant misunderstandings.

On the other hand, for learners like me who tend toward introversion, the asynchronous nature of text-based learning environments is a huge advantage. I couldn't count the number of times that I have wanted to contribute to an in-class discussion, but needed too much time to formulate a coherent response, and before I knew it, the conversation had moved on. My point was no longer relevant, having been resolved by those in the class who were more extroverted and ready with an answer. A text-based environment, however, gives me #strong[time to think, write, revise, and then post] my response.

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Social Presence
]
)
]
Garrison, et.al. describe social presence as \>the ability of participants in the Community of Inquiry to project their personal characteristics into the community, thereby presenting themselves to the other participants as "real people." (p.~89)

In any community, and especially the TWU community, the ability to #emph[belong] and to be accepted as a whole and integrated person is critical to people feeling like they #emph[actually do belong];. It is for this reason that many experienced online educators encourage a more colloquial style of writing in online forums or blogs. Strict adherence to APA or other style guides virtually eliminates self-referential language such as personal pronouns. It is hard to project your personal characteristics as a real person when you can only refer to yourself in the third person.

By allowing a more personal style and the projection of self into the community, it is thought that students will build a sense of trust in the community and feel more empowered to participate in the difficult work of changing their minds. Social presence supports cognitive presence by allowing the learning environment to be safe and welcoming.

#block[
#heading(
level: 
4
, 
numbering: 
none
, 
[
Teaching Presence
]
)
]
This final element of the CoI model is the design and facilitation of the learning experience \>to support and enhance social and cognitive presence for the purpose of realizing educational outcomes. (p.~90).

Teaching presence can be a shared function between members of the community. Garrison, et al.~point out that the design of the experience is typically performed by the teacher, and the facilitation is more often shared. In a connected course like this one, there is a greater emphasis on shared facilitation in a community of learners compared to what might be experienced in a f2f (face to face) course. It is in this shared discourse in a safe environment that allows learners to engage in the difficult cognitive work of learning.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Activity: Exploring the Community of Inquiry
]
)
]
#block[
#strong[Read] #link("https://www-sciencedirect-com.twu.idm.oclc.org/science/article/pii/S1096751600000166")[#emph[Critical inquiry in a text-based environment: Computer conferencing in higher education];] (access through the TWU library).

If you haven't done so previously, sign up for and activate #link("https://hypothes.is/signup")[hypothes.is] and while you are reading the article, leave some annotations that connect what you are reading to your own experience.

Use the tag 'ldrs463-663' in any annotations you create so that we can all find each other.

#link("https://servicehub.twu.ca/TDClient/1904/Portal/KB/ArticleDet?ID=146716")[Click here for assistance getting set up with hypothes.is.]

As you read, consider a time where you experienced a learning environment where the three presences described in the CoI were apparent. Consider the following questions and optionally, write your responses in a new post on your blog.

- Were all three presences demonstrated?
- Which of the three were most obvious? Least?
- Which presence is most important for you?

#block[
This is an ungraded activity, but is designed to help prepare you for the assessments in this course. Throughout the course you are encouraged to take notes in a journal of some sort. Refer to these notes as you complete your assessments.

]
]
== Modes of Interaction
<modes-of-interaction>
For this next topic, we will look at what we mean by 'interaction', a word which is thrown around a lot in educational technology, but…

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Activity: What Is Interaction?
]
)
]
#block[
#link("https://youtu.be/gpGjexZcJdg")[Watch: #emph[You keep using that word.];]

#link("https://www.youtube-nocookie.com/embed/G2y8Sx4B2Sk?si=ZuZoOVhJU0xcsS6U")

Before we get into the the topic of interaction, please take a few minutes to answer the following questions about scenarios that may or may not be considered 'interaction'. (Note that you can check your answer right away, and then click the arrow for the next example.)

What do you think? Do you agree with the 'correct' and 'incorrect' responses on the quiz?

]
=== Interaction
<interaction>
Anderson (2003) argues that, despite the lack of clarity around definitions of interaction, there seems to be a general understanding that interaction of some sort is a requirement for learning. He settles on the definition from Wagner (1994, p.8)

#quote(block: true)[
Reciprocal events that require at least two objects and two actions. Interactions occur when these objects and events mutually influence one another.
]

He provides a model of interaction in learning environments that includes three main agents in the process: students, teachers, and content (Figure 1.2).

#figure([
#box(image("assets/u2/Modes-Interaction-Anderson_new.png", width: 4.16667in))
], caption: figure.caption(
position: bottom, 
[
Figure 1.2 Anderson's Modes of Interaction (2003)
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


At each point of the triangle are the agents in an educative process. The arrows between them indicate the two-way communication described by Wagner, and the recursive arrows above or below the agents are secondary forms of interaction.

=== Other Models of Interaction
<other-models-of-interaction>
Kanuka (2011) describes a modified model of interaction which presumes that all educational interactions occur in the context of some sort of content (Figure 1.3).

#figure([
#box(image("assets/u2/Kanuka-Modes-of-Interaction_new.png", width: 2.91667in))
], caption: figure.caption(
position: bottom, 
[
Figure 1.3 Kanuka's Model of Interaction (2011)
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


In Anderson's model, content is an agent in the process, but in Kanuka's model, content of some sort is assumed to be the foundation of learning environments and that interactions between and among learners and instructors happens in the context of making sense of the content. The content itself does not have agency.

A combination of these two models was described by Madland (2014). Madland's model, shown in Figure 1.4, is a return to Anderson's three-sided model except with the addition of peer interactions, and all interactions between agents occuring in the context of the content that is to be learned. Also added are the three sides of the model representing structured learning activities designed specifically to enhance the educative effects of the interactions.

#figure([
#box(image("assets/u2/Modes-of-Interaction-Madland_new.png", width: 4.16667in))
], caption: figure.caption(
position: bottom, 
[
Figure 1.4 Madland's Model of Interaction (2014)
]), 
kind: "quarto-float-fig", 
supplement: "Figure", 
)


It is not enough to simply expect interactions between learners and instructors to be goal-oriented towards learning outcomes. Educators must design specific activities (teaching presence) to create the conditions (social presence) for learning to occur (cognitive presence). An example of this can be seen in the seemingly ubiquitous 'Group Project' assigned in so many undergraduate courses. Sometimes, groups are allowed to form themselves, other times, the instructor assigns groups, or there is some sort of random process to create groups. However they are formed, groups too often fall into a pattern of behaviour where one or two of the students do most of the work and the remaining group members engage in social loafing and benefit from their peers' work.

An alternative practice is to engage groups in a specific structured process of cooperation where everybody must do their work, or else the entire group suffers. An example is to have students work in peer review partners where students submit their assignments to their peer review partner who then provides feedback based on specific questions and categories of comments. When the original students receives their partner's feedback, they may choose how to integrate the suggestions into the final assignment that they submit to their instructor. Each student is then graded on the quality of their finished assignment, the quality of the feedback that they provided, and on the rationale for how they incorporated the peer review into their own work.

There are myriad structures that can be used to ensure that interactions are inclined towards producing student learning, and we will introduce you to some of those in unit 5.

#block[
#heading(
level: 
3
, 
numbering: 
none
, 
[
Activity: Theoretical Rationale for Interaction
]
)
]
#block[
Read the following article by Terry Anderson, #link("http://www.irrodl.org/index.php/irrodl/article/view/149/230")[#emph[Getting the mix right again: An updated and theoretical rationale for interaction];];. As you read, consider what interactions you have experiences in online or f2f courses.

]
== Interaction Equivalency Theorem
<interaction-equivalency-theorem>
For our last topic of this unit, we'll explore Anderson's (2003) #emph[Interaction Equivalency Theorem];, stated as

#quote(block: true)[
Deep and meaningful formal learning is supported as long as one of the three forms of interaction (student--teacher; student-student; student-content) is at a high level. The other two may be offered at minimal levels, or even eliminated, without degrading the educational experience. High levels of more than one of these three modes will likely provide a more satisfying educational experience, though these experiences may not be as cost or time effective as less interactive learning sequences. (p.~4)
]

At TWU, there has always been a significant emphasis placed on student-teacher interactions. This can be seen in small class sizes and opportunities for students to be involved in faculty-led research projects and travel studies. Distance education, however, has long suffered from a distinct lack of student-teacher and student-student interactions. For many years, distance education was delivered either through the post or through one-way media such as radio or TV, virtually eliminating interactions. This led to a pervasive view that distance education courses and programs were second-rate at best.

However, now that modern communication infrastructure has developed to the point that media-rich, synchronous, two-way communication is almost free, opportunities for distance learning environments to include high levels of student-student and student-teacher interaction are much more feasible.

One problem remains, though, and that is that student-teacher interaction is a scarce commodity. It is costly to hire enough faculty to enable one-on-one or small-group interaction between students and faculty. The distance educator's response to this challenge is to front-load the faculty input (high-level disciplinary expertise or cognitive presence) into the course materials and to de-couple 'interaction' from both time and place.

In an asynchronous, text-based environment, students and teachers do not need to be present in the same place at the same time in order to enjoy rich interactions.

#block[
#heading(
level: 
2
, 
numbering: 
none
, 
[
Unit Summary
]
)
]
In this unit of LDRS 463/663, you are introduced to the Community of Inquiry (CoI) model, which emphasizes the interconnected roles of cognitive, social, and teaching presences in online learning environments. The unit explores how these presences foster meaningful learning experiences through interaction, informed by the educational theory of social constructivism. Additionally, the unit examines various modes of interaction, including student-teacher, student-student, and student-content dynamics, and introduces Anderson's Interaction Equivalency Theorem, which explains how deep learning can occur with a focus on one key mode of interaction.

#block[
Before you move on to the next unit, you may want to check that you are able to:

- Analyze the characteristics of the Community of Inquiry model.
- Evaluate different modes of interaction.
- Criticize the Interaction Equivalency Theorem.

]


 
  
#set bibliography(style: "apa.csl") 


#bibliography("references.bib")

