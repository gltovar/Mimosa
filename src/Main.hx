import js.html.SpanElement;
import js.html.AnchorElement;
import js.html.ImageElement;
import js.html.Element;
import js.Browser;
import js.html.svg.RectElement;
import js.html.DivElement;
import js.html.Event;
import js.html.svg.SVGElement;
import js.html.svg.LineElement;
import js.Browser.document;
import eventtypes.DOMMutationEventType;
import haxe.Http;
import haxe.Json;


// schema for json data related to resume data

typedef TimelineHeader = {
	var id:String;
	var title:String;
	var description:String;
}

typedef TimelineData = {
	var type:String;
	var start:Float;
	var duration:Float;
}

typedef ProjectBlock = {
	var description:String;
	var percentage:Float;
	var timeline:Array<TimelineData>;
}

typedef JobBlock = {
	var title:String;
	var duration:String;
	var yearStart:String;
	var yearEnd:String;
	var company:String;
	var location:String;
	var tools:String;
	var projectBlocks:Array<ProjectBlock>;
}

typedef InspriationBlock = {
	var title:String;
	var medium:String;
	var type:String;
	var description:String;
}

typedef PortfolioBlock = {
	var title:String;
	var src:String;
	var link:String;
}

typedef PersonalInfo = {
	var name:String;
	var objective:String;
	var contactInfo:String;
	var image:String;
}

typedef ResumeData = {
	var personalInfo:PersonalInfo;
	var timelineHeaders:Array<TimelineHeader>;
	var jobBlocks:Array<JobBlock>;
	var inspirations:Array<InspriationBlock>;
	var portfolio:Array<PortfolioBlock>;
}

class HTMLEnum{
	public inline static var DIV:Int = 0;
	public inline static var IMAGE:Int = 1;
	public inline static var HR:Int = 2;
	public inline static var ANCHOR:Int = 3;
	public inline static var SPAN:Int = 4;
}

// need to disable dce to get this to work in haxe 4p5
// enum HTMLEnum{
// 	DIV;
// 	IMAGE;
// 	HR;
// }

class Main {

	static var resumeData:ResumeData;
	static var domContentLoaded:Bool = false;
	static var resumeDataLoaded:Bool = false;

	// these are used to keep track of the project colors and roll over when the limit is hit
	static var currentProjectColor:Int = 0;
	static var maxProjectColor:Int = 9;
	static var timelineHeaderMap:Map<String, Int> = new Map<String, Int>();

	static function main() {
		// both waiting for the page to be ready as well as the resume data to be loaded
		document.addEventListener(DOMMutationEventType.DOMContentLoaded, onDomContentLoaded);

		var httpRequest = new haxe.Http("resume_data.json");
		httpRequest.async = true;
		httpRequest.onData = receiveResumeData;
		httpRequest.onError = dataError;
		httpRequest.request();
	}

	static function receiveResumeData(data:String):Void
	{
		resumeData = Json.parse(data);
		resumeDataLoaded = true;
		renderResume();
	}

	static function dataError(error):Void
	{
		trace("Error: " + error);
	}

	static function onDomContentLoaded(e:Event):Void
	{
		domContentLoaded = true; 

		renderResume();
	}

	// renderResume only starts when both the page is loaded and we have the resume data
	// THOUGHT: It would be really cool if .less css could generate a static list of var names
	static function renderResume():Void
	{
		if(!domContentLoaded || !resumeDataLoaded)
		{
			return;
		}
		
		var resumeContainer = setupHTMLElement(HTMLEnum.DIV, ['resume-container'], document.querySelector("body"));

		// start resume header
		var personalContainer = setupHTMLElement(HTMLEnum.DIV, ['personal-container'], resumeContainer);
		var personalTextContainer = setupHTMLElement(HTMLEnum.DIV, ['personal-text-container'], personalContainer);
		var personalTitle = setupHTMLElement(HTMLEnum.DIV, ['personal-title'], personalTextContainer);
		personalTitle.innerText = resumeData.personalInfo.name;
		var personalSubtitle = setupHTMLElement(HTMLEnum.DIV, ['personal-subtitle'], personalTextContainer);
		personalSubtitle.innerText = resumeData.personalInfo.objective;
		var personalSubtitle2 = setupHTMLElement(HTMLEnum.DIV, ['personal-subtitle'], personalTextContainer);
		personalSubtitle2.innerText = resumeData.personalInfo.contactInfo;
		var personalImage:ImageElement = cast setupHTMLElement(HTMLEnum.IMAGE, ['personal-image'], personalContainer);
		personalImage.src = resumeData.personalInfo.image;
		// end resume header

		var resumeBodyContainer = setupHTMLElement(HTMLEnum.DIV, ['resume-body-container'], resumeContainer);

		var professionalLHSContainer = setupHTMLElement(HTMLEnum.DIV, ['professional-lhs-container'], resumeBodyContainer);
		
		var personalRHSContainer = setupHTMLElement(HTMLEnum.DIV, ['personal-rhs-container'], resumeBodyContainer);

		var rhsTitle = setupHTMLElement(HTMLEnum.DIV, ['breakdown-position'], personalRHSContainer);
		rhsTitle.textContent = "PORTFOLIO";

		// generate portfolio items
		for(i in 0...resumeData.portfolio.length)
		{
			var portfolioItem = resumeData.portfolio[i];

			var rhsAnchorContainer:AnchorElement = cast setupHTMLElement(HTMLEnum.ANCHOR, [], personalRHSContainer);
			rhsAnchorContainer.href = portfolioItem.link;

			var rhsContentContainer = setupHTMLElement(HTMLEnum.DIV, ['portfolio-item'], rhsAnchorContainer);
			rhsContentContainer.style.backgroundImage = 'url(${portfolioItem.src})';

			var videoIcon = setupHTMLElement(HTMLEnum.DIV, ['video-icon','noprint'], rhsContentContainer);
			videoIcon.style.backgroundImage = "url(video_icon.svg)";
		}


		// start timeline headers
		var resumeTitleContainer = setupHTMLElement(HTMLEnum.DIV, ['resume-title-container'], professionalLHSContainer);
		var timelineHeaderContainer = setupHTMLElement(HTMLEnum.DIV, ['timeline-header-container'], resumeTitleContainer);

		var prevHeaderItem:Element = null;
		for(i in 0...resumeData.timelineHeaders.length)
		{
			var timelineHeaderData = resumeData.timelineHeaders[i];
			timelineHeaderMap[timelineHeaderData.id] = i+1; // building this map to allow timelines to match headers

			var timelineHeaderItem = setupHTMLElement(HTMLEnum.DIV, ['timeline-header-item', 'header${i+1}']);
			
			var timelineHeaderText = setupHTMLElement(HTMLEnum.DIV, ['timeline-header-text'], timelineHeaderItem);

			var timelineHeaderTitle = setupHTMLElement(HTMLEnum.DIV, ['timeline-header-title'], timelineHeaderText);
			timelineHeaderTitle.innerText = timelineHeaderData.title;

			var timelineHeaderDescription = setupHTMLElement(HTMLEnum.DIV, ['timeline-header-description'], timelineHeaderText);
			timelineHeaderDescription.innerText = timelineHeaderData.description;

			var parentDiv = (prevHeaderItem == null) ? timelineHeaderContainer : prevHeaderItem;

			parentDiv.appendChild(timelineHeaderItem);
			prevHeaderItem = timelineHeaderItem;
		}
		// end timeline headers

		// start jobblocks
		for( jobBlock in resumeData.jobBlocks)
		{
			var completeJobContainer = setupHTMLElement(HTMLEnum.DIV, ['complete-job-container'], professionalLHSContainer);
			var headerContainer = setupHTMLElement(HTMLEnum.DIV, ['header-container'], completeJobContainer);
			var timelineYearEnd = setupHTMLElement(HTMLEnum.DIV, ['timeline-year'], headerContainer);
			timelineYearEnd.innerText = jobBlock.yearEnd;
			var jobContainer = setupHTMLElement(HTMLEnum.DIV, ['job-container'], completeJobContainer);
			var experienceBreakdownContainer = setupHTMLElement(HTMLEnum.DIV, ['experience-breakdown-container'], jobContainer);
			
			// start generation of the left side timeline block for job
			var svg:SVGElement = createSVGElement("svg");
			svg.width.baseVal.valueAsString = "100%";
			svg.height.baseVal.valueAsString = "100px";

			var lineCount = 5; // - 1
			var lineSpacing = (1 / lineCount) * 100;
			for(i in 1...lineCount)
			{
				var line:LineElement = cast(createSVGElement("line"));
				line.x1.baseVal.valueAsString = (i * lineSpacing) + "%";
				line.x2.baseVal.valueAsString = (i * lineSpacing) + "%";

				line.y1.baseVal.valueAsString = "0%";
				line.y2.baseVal.valueAsString = "100%";

				line.classList.add("test-line");

				svg.appendChild(line);
			}

			experienceBreakdownContainer.appendChild(svg);

			// start title, position, location block
			var infoBreakdownContainer = setupHTMLElement(HTMLEnum.DIV, ['info-breakdown-container'], jobContainer);
			var breakdownPosition = setupHTMLElement(HTMLEnum.DIV, ['breakdown-position'], infoBreakdownContainer);
			breakdownPosition.innerText = jobBlock.title;
			infoBreakdownContainer.appendChild(document.createHRElement());
			var yearLocationContainer = setupHTMLElement(HTMLEnum.DIV, ['year-location-container'], infoBreakdownContainer);
			infoBreakdownContainer.appendChild(document.createHRElement());
			var yearTitle = setupHTMLElement(HTMLEnum.DIV, ['year-title'], yearLocationContainer);
			yearTitle.innerText = jobBlock.duration;
			var locationContainer = setupHTMLElement(HTMLEnum.DIV, ['location-container'], yearLocationContainer);
			var employerTitle:SpanElement = cast setupHTMLElement(HTMLEnum.SPAN, ['employer-title'], locationContainer);
			employerTitle.innerText = jobBlock.company;
			var locationTitle:SpanElement = cast setupHTMLElement(HTMLEnum.SPAN, ['location-title'], locationContainer);
			locationTitle.innerText = jobBlock.location;
			// end title, position, location block

			// start drawing the breakdown timeline and project blocks
			var startPercentage = 0.0;
			for( projectBlockIndex in 0...jobBlock.projectBlocks.length)
			{
				var projectBlock = jobBlock.projectBlocks[projectBlockIndex];

				var jobDescription = cast setupHTMLElement(HTMLEnum.DIV, ['job-description','project-shared','project${currentProjectColor+1}'], infoBreakdownContainer);
				jobDescription.innerText = projectBlock.description;

				// keep track of current starting percentage
				startPercentage += (projectBlockIndex == 0) ? 0 : jobBlock.projectBlocks[projectBlockIndex-1].percentage;

				var rect:RectElement = cast(createSVGElement("rect"));
				rect.classList.add('fill-project-${currentProjectColor+1}');
				currentProjectColor = (++currentProjectColor >= maxProjectColor) ? 0 : currentProjectColor;

				rect.classList.add("fill-low-opacity");
				rect.x.baseVal.valueAsString = "0%";
				rect.y.baseVal.valueAsString = (startPercentage*100) + "%";
				rect.width.baseVal.valueAsString = "100%";
				rect.height.baseVal.valueAsString = (projectBlock.percentage * 100) + "%";
				svg.appendChild(rect);


				for( timelineBlockIndex in 0...projectBlock.timeline.length)
				{
					var timelineBlock = projectBlock.timeline[timelineBlockIndex];

					var xVal = timelineHeaderMap[timelineBlock.type] * lineSpacing;
					var lineClass = 'test-line-${timelineHeaderMap[timelineBlock.type]}';

					var svgTimelineLine:LineElement = cast(createSVGElement("line"));
					svgTimelineLine.classList.add(lineClass);
					svgTimelineLine.x1.baseVal.valueAsString = xVal + "%";
					svgTimelineLine.x2.baseVal.valueAsString = xVal + "%";
					
					var timeLineStartPercentage = startPercentage + projectBlock.percentage;					

					var y1 = timelineBlock.start * projectBlock.percentage;
					y1 = timeLineStartPercentage - y1;
					y1 *= 100;
					svgTimelineLine.y1.baseVal.valueAsString =  y1 + "%";

					var y2 = timelineBlock.start + timelineBlock.duration;
					y2 *= projectBlock.percentage;
					y2 = timeLineStartPercentage - y2;
					y2 *= 100;
					svgTimelineLine.y2.baseVal.valueAsString = y2 + "%";
					svg.appendChild(svgTimelineLine);
				}
			}
			// end timeline and project blocks
			
			if(jobBlock.yearStart != null && jobBlock.yearStart.length > 0)
			{
				var footerContainer = cast setupHTMLElement(HTMLEnum.DIV, ['header-container'], completeJobContainer);

				var timelineYearStart = cast setupHTMLElement(HTMLEnum.DIV, ['timeline-year'], footerContainer);
				timelineYearStart.innerText = jobBlock.yearStart;
			}
			// end project block
		}

		// need page to render one frame to adjust timeling heights properly
		Browser.window.requestAnimationFrame(updateSVGTimelineHeight);
	}

	static function updateSVGTimelineHeight(d:Float):Void
	{
		var braceWidth = 10;
		var braceSpacing = 5;
		var jobContainers = document.querySelectorAll(".job-container");
		trace(jobContainers);
		for(jobCotainerBlock in jobContainers)
		{
			var jobContainerElement:DivElement = cast(jobCotainerBlock);
			var jobContainerRect = jobContainerElement.getBoundingClientRect();

			var infoBreakdownDiv = jobContainerElement.querySelector(".info-breakdown-container");

			var svg:SVGElement = cast(jobContainerElement.querySelector("svg"));
			svg.height.baseVal.valueAsString = infoBreakdownDiv.clientHeight + "px";

			var svgRect = svg.getBoundingClientRect();

			// Only know the height of the SVGs AFTER they are drawn, need to go back and update the brackets positioning
			for(childElement in svg.children)
			{
				if(childElement.nodeName != "path")
				{
					continue;
				}
				trace('w: ${svgRect.width}, h: ${jobContainerRect.height}');
			}
		}

	}

	static function setupHTMLElement(elementEnum:Int, classList:Array<String> = null, parent:Element = null)
	{
		var element:Element = null;
		//HTMLEnum.
		switch (elementEnum)
		{
			case HTMLEnum.DIV:
				element = document.createDivElement();
			case HTMLEnum.IMAGE:
				element = document.createImageElement();
			case HTMLEnum.HR:
				element = document.createHRElement();
			case HTMLEnum.ANCHOR:
				element = document.createAnchorElement();
			case HTMLEnum.SPAN:
				element = document.createSpanElement();
			default:
				trace("unknown element passed in");
				return null;
		}

		if(classList != null)
		{
			for(classItem in classList)
			{
				if(classItem.length > 0)
				{
					element.classList.add(classItem);
				}
				else
				{
					trace("Warning html class was empty");
				}
			}
		}

		if(parent != null)
		{
			parent.appendChild(element);
		}
		
		return element;
	}

	//https://stackoverflow.com/questions/20539196/creating-svg-elements-dynamically-with-javascript-inside-html
	// using this to be able to create svg elements with code
	static function createSVGElement(n):SVGElement
	{
		return cast(document.createElementNS("http://www.w3.org/2000/svg", n));
	}
}
