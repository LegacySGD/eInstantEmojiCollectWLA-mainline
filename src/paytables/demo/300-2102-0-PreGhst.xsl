<?xml version="1.0" encoding="UTF-8" ?>
<xsl:stylesheet version="1.0" xmlns:xsl="http://www.w3.org/1999/XSL/Transform" xmlns:x="anything">
	<xsl:namespace-alias stylesheet-prefix="x" result-prefix="xsl" />
	<xsl:output encoding="UTF-8" indent="yes" method="xml" />
	<xsl:include href="../utils.xsl" />

	<xsl:template match="/Paytable">
		<x:stylesheet version="1.0" xmlns:java="http://xml.apache.org/xslt/java" xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
			exclude-result-prefixes="java" xmlns:lxslt="http://xml.apache.org/xslt" xmlns:my-ext="ext1" extension-element-prefixes="my-ext">
			<x:import href="HTML-CCFR.xsl" />
			<x:output indent="no" method="xml" omit-xml-declaration="yes" />

			<!-- TEMPLATE Match: -->
			<x:template match="/">
				<x:apply-templates select="*" />
				<x:apply-templates select="/output/root[position()=last()]" mode="last" />
				<br />
			</x:template>

			<!--The component and its script are in the lxslt namespace and define the implementation of the extension. -->
			<lxslt:component prefix="my-ext" functions="formatJson,retrievePrizeTable,getType">
				<lxslt:script lang="javascript">
					<![CDATA[
					// Limited to 50 strings of Debuging
					var debugFeed = [];
					var debugFlag = false;
					
					// Format instant win JSON results.
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function formatJson(jsonContext, translations, prizeTable, convertedPrizeValues, prizeNamesDesc)
					{
						var scenario = getScenario(jsonContext);
						var gameData = scenario.split('|');
						var gridCols = gameData[0].split(',');
						var gameTurns = gameData[1].split(',');
						var prizeNames = (prizeNamesDesc.substring(1)).split(',');
						var prizeValues = (convertedPrizeValues.substring(1)).split('|');
						//var maxColLength = getMaxColLength(gridCols);

						//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////			
						// Print Translation Table to !DEBUG
						var index = 1;
						registerDebugText("Translation Table");
						while(index < translations.item(0).getChildNodes().getLength())
						{
							var childNode = translations.item(0).getChildNodes().item(index);
							registerDebugText(childNode.getAttribute("key") + ": " +  childNode.getAttribute("value"));
							index += 2;
						}

						// !DEBUG
						//registerDebugText("Translating the text \"softwareId\" to \"" + getTranslationByName("softwareId", translations) + "\"");
						///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

						// Output winning numbers table.
						var r = [];
						var shownWin = [false,false,false,false,false];
						var showWin = false;
						var prizeText = '';
						
						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							r.push('<tr>');
								r.push('<td class="tablebody">');
									r.push(getTranslationByName("outcomes", translations));
								r.push('</td>');
							r.push('</tr>');
						r.push('</table>');

						r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');

							for (turn=1, totals=[0,0,0,0,0], totalStr='', extraTurn=false, totalIndex=-1, totalTurn=0, winTotals=[30,28,25,20,15], instantWins=[], instantWin=false; turn<=gameTurns.length; turn++)
							{
								r.push('<tr>');
									r.push('<td class="tablehead" width="20%">');
										r.push(getTranslationByName("turn", translations) + ' ' + turn);
									r.push('</td>');
									r.push('<td class="tablehead" width="20%">');
										r.push(getTranslationByName("emoticon", translations));
									r.push('</td>');
									r.push('<td class="tablehead" width="20%">');
										r.push(getTranslationByName("numberCollected", translations));
									r.push('</td>');
									r.push('<td class="tablehead" width="20%">');
										r.push(getTranslationByName("cumulativeTotal", translations));
									r.push('</td>');
									r.push('<td class="tablehead" width="20%">');
										r.push(getTranslationByName("prize", translations));
									r.push('</td>');
								r.push('</tr>');

								extraTurn = false;
								instantWin = false;
								totalTurn = 0;

								if (isNaN(parseInt(gameTurns[turn-1])))
						{
									totalIndex = gameTurns[turn-1].charCodeAt(0) - 'A'.charCodeAt(0);

									for (col=0; col<gridCols.length; col++)
									{
										for (colCell=0; colCell<6; colCell++)
										{
											if (gridCols[col][colCell] == gameTurns[turn-1].toLowerCase())
						{
												extraTurn = true;
											}

											if (gridCols[col][colCell].toUpperCase() == gameTurns[turn-1])
							{
												totalTurn++;
												totals[totalIndex]++;
											}
							}

										var turnRegExp = new RegExp(gameTurns[turn-1], 'gi');
										gridCols[col] = gridCols[col].substr(0,6).replace(turnRegExp,'') + gridCols[col].substr(6);
									}
							}
							else
							{
									instantWins.push(gameTurns[turn-1]);
									instantWin = true;
							}						

								for (symb=0; symb<totals.length; symb++)
								{
									prizeText = String.fromCharCode('A'.charCodeAt(0) + symb);
									showWin = ((totals[symb] >= winTotals[symb]) && !shownWin[symb]);
									//showWin = true;

 							r.push('<tr>');
								r.push('<td class="tablebody">');
											r.push('&nbsp;');
								r.push('</td>');
										r.push('<td class="tablebody">');
											r.push(getTranslationByName("symb" + prizeText, translations));
						r.push('</td>');						
										r.push('<td class="tablebody">');
											r.push(((symb == totalIndex) ? totalTurn : '0'));
						r.push('</td>');
										r.push('<td class="tablebody">');
											r.push(totals[symb] + '/' + winTotals[symb] + ' ' + ((showWin) ? getTranslationByName("win", translations) : ''));
								r.push('</td>');
						r.push('<td class="tablebody">');
											r.push(((showWin) ? prizeValues[prizeNames.indexOf(prizeText)] : ''));
						r.push('</td>');
						r.push('</tr>');						

									if (showWin)
									{
										shownWin[symb] = true;
									}
								}

						r.push('<tr>');
						r.push('<td class="tablehead">');
										r.push('&nbsp;');
						r.push('</td>');
						r.push('<td class="tablehead">');
										r.push(getTranslationByName("extras", translations));
						r.push('</td>');
									r.push('<td class="tablehead" colspan="2">');
										r.push('&nbsp;');
						r.push('</td>');
						r.push('<td class="tablehead">');
						r.push(getTranslationByName("prize", translations));
								r.push('</td>');
 							r.push('</tr>');

								r.push('<tr>');
							r.push('<td class="tablebody">');
										r.push('&nbsp;');
									r.push('</td>');
									r.push('<td class="tablebody">');
										r.push(getTranslationByName("instantWin", translations));
									r.push('</td>');
									r.push('<td class="tablebody">');
										r.push(((instantWin) ? '1' : '0'));
									r.push('</td>');
									r.push('<td class="tablebody">');
										r.push('&nbsp;');
							r.push('</td>');							
							r.push('<td class="tablebody" colspan="2">');
										r.push(((instantWin) ? prizeValues[prizeNames.indexOf('IW' + instantWins[instantWins.length-1])] : ''));
							r.push('</td>');
								r.push('</tr>');

								r.push('<tr>');
							r.push('<td class="tablebody">');
										r.push('&nbsp;');
							r.push('</td>');
								r.push('<td class="tablebody">');
										r.push(getTranslationByName("extraTurn", translations));
								r.push('</td>');
								r.push('<td class="tablebody">');
										r.push(((extraTurn) ? '1' : '0'));
									r.push('</td>');
									r.push('<td class="tablebody" colspan="2">');
										r.push('&nbsp;');
								r.push('</td>');						
								r.push('</tr>');

								r.push('<tr>');
								r.push('<td class="tablebody">');
										r.push('&nbsp;');
									r.push('</td>');
							r.push('</tr>');
						}
						
						r.push('</table>');

						////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
						// !DEBUG OUTPUT TABLE
						
						if(debugFlag)
						{
							// DEBUG TABLE
							//////////////////////////////////////
							r.push('<table border="0" cellpadding="2" cellspacing="1" class="gameDetailsTable">');
							for(var idx = 0; idx < debugFeed.length; ++idx)
 						{
								if(debugFeed[idx] == "")
									continue;
								r.push('<tr>');
 							r.push('<td class="tablebody">');
								r.push(debugFeed[idx]);
 							r.push('</td>');
 						r.push('</tr>');
							}
							r.push('</table>');
						}

						return r.join('');
					}

					// Input: A list of Price Points and the available Prize Structures for the game as well as the wagered price point
					// Output: A string of the specific prize structure for the wagered price point
					function retrievePrizeTable(pricePoints, prizeStructures, wageredPricePoint)
					{
						var pricePointList = pricePoints.split(',');
						var prizeStructStrings = prizeStructures.split('|');

						for(var i=0; i<pricePoints.length; i++)
						{
							if(wageredPricePoint == pricePointList[i])
							{
								return prizeStructStrings[i];
							}
						}

						return '';
					}

					// Input: Json document string containing 'scenario' at root level.
					// Output: Scenario value.
					function getScenario(jsonContext)
					{
						// Parse json and retrieve scenario string.
						var jsObj = JSON.parse(jsonContext);
						var scenario = jsObj.scenario;

						// Trim null from scenario string.
						scenario = scenario.replace(/\0/g, '');

						return scenario;
					}

					// Input: Json document string containing 'amount' at root level.
					// Output: Price Point value.
					function getPricePoint(jsonContext)
					{
						// Parse json and retrieve price point amount
						var jsObj = JSON.parse(jsonContext);
						var pricePoint = jsObj.amount;

						return pricePoint;
					}

					////////////////////////////////////////////////////////////////////////////////////////
					function registerDebugText(debugText)
					{
						debugFeed.push(debugText);
					}
					
					/////////////////////////////////////////////////////////////////////////////////////////
					function getTranslationByName(keyName, translationNodeSet)
					{
						var index = 1;
						while(index < translationNodeSet.item(0).getChildNodes().getLength())
						{
							var childNode = translationNodeSet.item(0).getChildNodes().item(index);
							
							if(childNode.name == "phrase" && childNode.getAttribute("key") == keyName)
							{
								registerDebugText("Child Node: " + childNode.name);
								return childNode.getAttribute("value");
							}
							
							index += 1;
						}
					}

					// Grab Wager Type
					// @param jsonContext String JSON results to parse and display.
					// @param translation Set of Translations for the game.
					function getType(jsonContext, translations)
					{
						// Parse json and retrieve wagerType string.
						var jsObj = JSON.parse(jsonContext);
						var wagerType = jsObj.wagerType;

						return getTranslationByName(wagerType, translations);
					}
					]]>
				</lxslt:script>
			</lxslt:component>

			<x:template match="root" mode="last">
				<table border="0" cellpadding="1" cellspacing="1" width="100%" class="gameDetailsTable">
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWager']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/WagerOutcome[@name='Game.Total']/@amount" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
					<tr>
						<td valign="top" class="subheader">
							<x:value-of select="//translation/phrase[@key='totalWins']/@value" />
							<x:value-of select="': '" />
							<x:call-template name="Utils.ApplyConversionByLocale">
								<x:with-param name="multi" select="/output/denom/percredit" />
								<x:with-param name="value" select="//ResultData/PrizeOutcome[@name='Game.Total']/@totalPay" />
								<x:with-param name="code" select="/output/denom/currencycode" />
								<x:with-param name="locale" select="//translation/@language" />
							</x:call-template>
						</td>
					</tr>
				</table>
			</x:template>

			<!-- TEMPLATE Match: digested/game -->
			<x:template match="//Outcome">
				<x:if test="OutcomeDetail/Stage = 'Scenario'">
					<x:call-template name="Scenario.Detail" />
				</x:if>
			</x:template>

			<!-- TEMPLATE Name: Scenario.Detail (base game) -->
			<x:template name="Scenario.Detail">
				<x:variable name="odeResponseJson" select="string(//ResultData/JSONOutcome[@name='ODEResponse']/text())" />
				<x:variable name="translations" select="lxslt:nodeset(//translation)" />
				<x:variable name="wageredPricePoint" select="string(//ResultData/WagerOutcome[@name='Game.Total']/@amount)" />
				<x:variable name="prizeTable" select="lxslt:nodeset(//lottery)" />

				<table border="0" cellpadding="0" cellspacing="0" width="100%" class="gameDetailsTable">
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='wagerType']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="my-ext:getType($odeResponseJson, $translations)" disable-output-escaping="yes" />
						</td>
					</tr>
					<tr>
						<td class="tablebold" background="">
							<x:value-of select="//translation/phrase[@key='transactionId']/@value" />
							<x:value-of select="': '" />
							<x:value-of select="OutcomeDetail/RngTxnId" />
						</td>
					</tr>
				</table>
				<br />			
				
				<x:variable name="convertedPrizeValues">

					<x:apply-templates select="//lottery/prizetable/prize" mode="PrizeValue"/>
				</x:variable>

				<x:variable name="prizeNames">
					<x:apply-templates select="//lottery/prizetable/description" mode="PrizeDescriptions"/>
				</x:variable>

				<x:value-of select="my-ext:formatJson($odeResponseJson, $translations, $prizeTable, string($convertedPrizeValues), string($prizeNames))" disable-output-escaping="yes" />
			</x:template>

			<x:template match="prize" mode="PrizeValue">
					<x:text>|</x:text>
					<x:call-template name="Utils.ApplyConversionByLocale">
						<x:with-param name="multi" select="/output/denom/percredit" />
					<x:with-param name="value" select="text()" />
						<x:with-param name="code" select="/output/denom/currencycode" />
						<x:with-param name="locale" select="//translation/@language" />
					</x:call-template>
			</x:template>
			<x:template match="description" mode="PrizeDescriptions">
				<x:text>,</x:text>
				<x:value-of select="text()" />
			</x:template>

			<x:template match="text()" />
		</x:stylesheet>
	</xsl:template>

	<xsl:template name="TemplatesForResultXSL">
		<x:template match="@aClickCount">
			<clickcount>
				<x:value-of select="." />
			</clickcount>
		</x:template>
		<x:template match="*|@*|text()">
			<x:apply-templates />
		</x:template>
	</xsl:template>
</xsl:stylesheet>
